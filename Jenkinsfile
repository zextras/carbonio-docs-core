// SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
//
// SPDX-License-Identifier: AGPL-3.0-only

library(
    identifier: 'jenkins-lib-common@v2.8.8',
    retriever: modernSCM([
        $class: 'GitSCMSource',
        credentialsId: 'jenkins-integration-with-github-account',
        remote: 'git@github.com:zextras/jenkins-lib-common.git',
    ])
)

properties(defaultPipelineProperties())

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
                gitMetadata()
            }
        }

        stage('Build deb/rpm') {
            steps {
                echo 'Building deb/rpm packages'
                buildStage([
                    parallelBuilds: false,
                    prepare: true,
                    addCarbonioRepos: true,
                    overrides: [
                        'rocky-8': [
                            branchBuildDirs: [
                                devel: [ 'rhel-only', '.' ]
                            ]
                        ],
                        'rocky-9': [
                            branchBuildDirs: [
                                devel: [ 'rhel-only', '.' ]
                            ]
                        ],
                    ]
                ])
            }
        }

        stage('Upload artifacts') {
            tools {
                jfrog 'jfrog-cli'
            }
            steps {
                uploadStage([
                    yapPaths: [
                        'rhel-only/yap.json',
                        'yap.json',
                    ] as Set
                ])
            }
        }
    }
}
