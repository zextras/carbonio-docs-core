// SPDX-FileCopyrightText: 2022 Zextras <https://www.zextras.com>
//
// SPDX-License-Identifier: AGPL-3.0-only

library(
    identifier: 'jenkins-lib-common@1.3.1',
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
                withCredentials([
                    usernamePassword(
                        credentialsId: 'artifactory-jenkins-gradle-properties-splitted',
                        passwordVariable: 'SECRET',
                        usernameVariable: 'USERNAME'
                    )
                ]) {
                    script {
                        env.REPO_ENV = env.GIT_TAG ? 'rc' : 'devel'
                    }

                    buildStage([
                        parallelBuilds: false,
                        prepare: true,
                        overrides: [
                            'ubuntu-jammy': [
                                preBuildScript: '''
                                    echo "machine zextras.jfrog.io" >> auth.conf
                                    echo "login $USERNAME" >> auth.conf
                                    echo "password $SECRET" >> auth.conf
                                    mv auth.conf /etc/apt
                                    echo "deb [trusted=yes] https://zextras.jfrog.io/artifactory/ubuntu-''' + env.REPO_ENV + ''' jammy main" \
                                    > zextras.list
                                    mv zextras.list /etc/apt/sources.list.d/
                                '''
                            ],
                            'ubuntu-noble': [
                                preBuildScript: '''
                                    echo "machine zextras.jfrog.io" >> auth.conf
                                    echo "login $USERNAME" >> auth.conf
                                    echo "password $SECRET" >> auth.conf
                                    mv auth.conf /etc/apt
                                    echo "deb [trusted=yes] https://zextras.jfrog.io/artifactory/ubuntu-''' + env.REPO_ENV + ''' noble main" \
                                    > zextras.list
                                    mv zextras.list /etc/apt/sources.list.d/
                                '''
                            ],
                            'rocky-8': [
                                preBuildScript: '''
                                    echo "[Zextras]" > zextras.repo
                                    echo "name=Zextras" >> zextras.repo
                                    echo "baseurl=https://$USERNAME:$SECRET@zextras.jfrog.io/artifactory/centos8-''' + env.REPO_ENV + '''/" >> zextras.repo
                                    echo "enabled=1" >> zextras.repo
                                    echo "gpgcheck=0" >> zextras.repo
                                    echo "gpgkey=https://$USERNAME:$SECRET@zextras.jfrog.io/artifactory/centos8-''' + env.REPO_ENV + '''/repomd.xml.key" >> zextras.repo
                                    mv zextras.repo /etc/yum.repos.d/zextras.repo
                                ''',
                                branchBuildDirs: [
                                    devel: [ 'rhel-only', '.' ]
                                ]
                            ],
                            'rocky-9': [
                                preBuildScript: '''
                                    echo "[Zextras]" > zextras.repo
                                    echo "name=Zextras" >> zextras.repo
                                    echo "baseurl=https://$USERNAME:$SECRET@zextras.jfrog.io/artifactory/rhel9-''' + env.REPO_ENV + '''/" >> zextras.repo
                                    echo "enabled=1" >> zextras.repo
                                    echo "gpgcheck=0" >> zextras.repo
                                    echo "gpgkey=https://$USERNAME:$SECRET@zextras.jfrog.io/artifactory/rhel9-''' + env.REPO_ENV + '''/repomd.xml.key" >> zextras.repo
                                    mv zextras.repo /etc/yum.repos.d/zextras.repo
                                ''',
                                branchBuildDirs: [
                                    devel: [ 'rhel-only', '.' ]
                                ]
                            ],
                        ]
                    ])
                }
            }
        }

        stage('Upload artifacts') {
            tools {
                jfrog 'jfrog-cli'
            }
            steps {
                uploadStage([
                    // this works because packages need to be listed only for rocky
                    packages: yapHelper.resolvePackageNamesFromFiles([
                        'rhel-only/yap.json',
                        'yap.json',
                    ] as Set)
                ])
            }
        }
    }
}
