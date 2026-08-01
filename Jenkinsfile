// SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
//
// SPDX-License-Identifier: AGPL-3.0-only

library(
    identifier: 'jenkins-lib-common@v4.3.2',
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
                }

                buildStage([
                    addCarbonioRepos: true,
                    parallelBuilds: false,
                    prepare: true,
                ])
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
