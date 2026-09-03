// SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
//
// SPDX-License-Identifier: AGPL-3.0-only

library(
    identifier: 'jenkins-lib-common@v4.10.2',
    retriever: modernSCM([
        $class: 'GitSCMSource',
        credentialsId: 'jenkins-integration-with-github-account',
        remote: 'git@github.com:zextras/jenkins-lib-common.git',
    ])
)

properties(defaultPipelineProperties())

// Per-leg overlay applied on top of the shared yap-*-v2 pod templates that
// live in infra-k3s jcasc. Only three things are overridden here; everything
// else (image, ccache hostPath mounts, nodeSelector, sidecars, deadlines,
// envVars) is inherited through inheritFrom + yamlMergeStrategy: merge().
//
// 1. resources.requests.cpu 1 -> 4
//    docs-core builds LibreOffice with `make build -j 4`. Linux CFS
//    apportions contended CPU by *requests*, not limits, so a 1-CPU
//    request left four compile jobs sharing a single core's worth of
//    shares whenever the worker had co-tenants. infra-k3s 447878f dropped
//    the request 2 -> 1 and 2b88dd9 dropped the memory request 4Gi -> 2Gi
//    ("doubles how many yap agents fit on a worker"), so contention became
//    the normal case and per-leg wall time went ~1h -> ~3h. Requesting 4
//    against the inherited limit of 4 makes the leg Guaranteed for CPU and
//    restores the parallelism `-j 4` already assumes. Memory is restated at
//    the inherited values so this block never depends on how the plugin
//    merges a partial resources stanza.
//
// 2. CCACHE_MAXSIZE
//    Nothing sets it anywhere today (no CCACHE_* key exists in jcasc), so
//    ccache runs on its 5G default while one docs-core leg issues ~490k
//    cacheable compilations. The cache is evicted long before it can be
//    reused, which is why the measured hit rate is 8-9% on every build
//    regardless of branch. The yap images whitelist CCACHE_MAXSIZE via
//    `Defaults env_keep`, so this value survives the `sudo yap build` that
//    buildStage runs. Each distro has its own hostPath cache dir, so this
//    is 25G per distro, not 25G total.
//
// 3. preferred nodeAffinity -> wrkr-4
//    Soft preference only. The inherited nodeSelector
//    (node-role.kubernetes.io/worker=true) still hard-restricts these pods
//    to workers, satisfying "must run on a worker"; this only *prefers*
//    wrkr-4 (the 24-core box) and falls back to any other worker when it
//    cannot fit.
String yapPodOverlay() {
    return '''\
apiVersion: v1
kind: Pod
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          preference:
            matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                  - wrkr-4.swarm.zextras.com
  containers:
    - name: yap
      resources:
        requests:
          cpu: "4"
          memory: "2Gi"
        limits:
          cpu: "4"
          memory: "10Gi"
      env:
        - name: CCACHE_MAXSIZE
          value: "25G"
'''
}

pipeline {
    agent {
        node {
            label 'base'
        }
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        disableConcurrentBuilds()
        skipDefaultCheckout()
        timeout(time: 6, unit: 'HOURS')
    }



    stages {
        stage('Setup') {
            steps {
                checkout scm
                script {
                    gitMetadata()
                }
            }
        }

        stage('Build deb/rpm') {
            steps {
                echo 'Building deb/rpm packages'
                script {
                    env.REPO_ENV = env.GIT_TAG ? 'rc' : 'devel'

                    // buildStage() allocates the shared yap-*-v2 labels directly
                    // and exposes no node/label override, so to get the overlay
                    // above onto the build pods this Jenkinsfile has to own the
                    // node allocation and hand buildStage the resulting label.
                    // Everything past that point -- Carbonio repo wiring, yap
                    // prepare/build, artifact stash + archive -- still runs
                    // through buildStage.buildPackagesForDistro, so no copy of
                    // that logic lives here. The initial 'staging' stash and the
                    // shared timestamp are what buildStage.call() would otherwise
                    // have produced, replicated verbatim.
                    stash(
                        includes: '**',
                        excludes: '**/target/test-classes/**,**/coverage-sources*/**,**/coverage-sources*.zip',
                        name: 'staging',
                    )

                    String ts = new Date().format('yyyyMMddHHmmss')

                    // Sequential on purpose: this replaces buildStage's
                    // parallelBuilds: false, and four concurrent 4-CPU legs
                    // would not co-schedule on one worker anyway.
                    distroConfig().each { distroId, cfg ->
                        stage(distroId) {
                            // buildStage derives `isV2 = cfg.node.contains('v2')`
                            // to decide whether to run yap under sudo, and yap
                            // needs root to write /opt/zextras during packaging.
                            // A generated POD_LABEL would not match, silently
                            // dropping sudo -- so keep 'v2' in the label.
                            String dynLabel = "docs-core-${distroId}-v2-${env.BUILD_NUMBER}"

                            podTemplate(
                                inheritFrom: cfg.node,
                                label: dynLabel,
                                yamlMergeStrategy: merge(),
                                yaml: yapPodOverlay(),
                            ) {
                                buildStage.buildPackagesForDistro([
                                    addCarbonioRepos: true,
                                    cfg: [
                                        node: dynLabel,
                                        artifactRegex: cfg.artifactRegex,
                                    ],
                                    distroId: distroId,
                                    prepare: true,
                                    stashName: 'staging',
                                    ts: ts,
                                ])
                            }
                        }
                    }
                }
            }
        }

        stage('Upload artifacts') {
            tools {
                jfrog 'jfrog-cli'
            }
            steps {
                uploadStage([
                    yapPath: 'yap.json',
                ])
            }
        }
    }
}
