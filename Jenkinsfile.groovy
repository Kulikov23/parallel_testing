/*
* Pipeline for parallel tests execution
* Author: Viacheslav Timonov (v.timonov@aimprosoft.com)
* Version 1.0
* */

def counts = "1\n2\n3\n4\n1C\n1.5C\n2C\n2.5C"
def scheme = "FEATURE\nSCENARIO"

node {
    stage 'Checkout'
    checkout scm
}

pipeline {
    agent {
        docker {
            image 'tsmaggot/docker-pipeline-chrome'
            args "-v maven-repository:/home/docker/.m2 --shm-size=\"1g\""
        }
    }
    parameters {
        choice(name: 'threads_count', choices: "${counts}", description: 'Number of threads')
        choice(name: 'parallel_scheme', choices: "${scheme}", description: 'Parallel scheme')
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }
    environment {
        MVN_GOAL = 'clean verify'
    }
    stages {
        stage('Execute tests') {
            steps {
                wrap([$class: 'Xvfb', screen: '1920x1080x16', 'timeout': 15, additionalOptions: '-fbdir /tmp']) {
                    sh "/usr/share/maven/bin/mvn ${env.MVN_GOAL} " +
                            "-Dcount.of.threads=${params.threads_count} " +
                            "-Dparallel.scheme=${params.parallel_scheme}"
                }
            }
        }
    }
    post {
        always {
            publishHTML(target: [
                    reportName           : 'Serenity',
                    reportDir            : 'target/site/serenity',
                    reportFiles          : 'index.html',
                    keepAll              : true,
                    alwaysLinkToLastBuild: true,
                    allowMissing         : false
            ])
        }
    }
}
