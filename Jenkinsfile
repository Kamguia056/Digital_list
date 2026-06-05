pipeline {
    agent any

    environment {
        APP_NAME        = 'digitallist'
        DOCKER_REGISTRY = 'registry.digitallist.app'
        DOCKER_IMAGE    = "${DOCKER_REGISTRY}/${APP_NAME}"
        FLUTTER_VERSION = '3.22.0'
        K8S_NAMESPACE   = 'digitallist'
        SONAR_PROJECT   = 'digitallist-mobile'
    }

    triggers {
        githubPush()
    }

    stages {

        // ── 1. Checkout ─────────────────────────────────────────
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log --oneline -5'
            }
        }

        // ── 2. Setup Flutter ────────────────────────────────────
        stage('Setup Flutter') {
            steps {
                sh '''
                    export PATH="$PATH:/opt/flutter/bin"
                    flutter --version
                    flutter pub get
                '''
            }
        }

        // ── 3. Lint & Static Analysis ───────────────────────────
        stage('Lint & Analysis') {
            parallel {
                stage('Flutter Analyze') {
                    steps {
                        sh '''
                            export PATH="$PATH:/opt/flutter/bin"
                            flutter analyze --no-fatal-infos 2>&1 | tee flutter_analyze.txt
                        '''
                    }
                }
                stage('Dart Format Check') {
                    steps {
                        sh '''
                            export PATH="$PATH:/opt/flutter/bin"
                            dart format --set-exit-if-changed lib/
                        '''
                    }
                }
            }
        }

        // ── 4. Tests ─────────────────────────────────────────────
        stage('Tests') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh '''
                            export PATH="$PATH:/opt/flutter/bin"
                            flutter test test/unit/ --coverage \
                              --reporter=json > test_results_unit.json
                        '''
                    }
                }
                stage('Widget Tests') {
                    steps {
                        sh '''
                            export PATH="$PATH:/opt/flutter/bin"
                            flutter test test/widget/ \
                              --reporter=json > test_results_widget.json
                        '''
                    }
                }
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'coverage/lcov-report',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }

        // ── 5. SonarQube Analysis ───────────────────────────────
        stage('SonarQube Analysis') {
            when {
                branch 'main'
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh """
                        sonar-scanner \
                          -Dsonar.projectKey=${SONAR_PROJECT} \
                          -Dsonar.sources=lib \
                          -Dsonar.tests=test \
                          -Dsonar.dart.coverage.reportPaths=coverage/lcov.info
                    """
                }
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        // ── 6. Build APK ────────────────────────────────────────
        stage('Build APK') {
            steps {
                sh '''
                    export PATH="$PATH:/opt/flutter/bin"
                    flutter build apk --release --no-tree-shake-icons
                    flutter build appbundle --release
                '''
                archiveArtifacts artifacts: 'build/app/outputs/**/*.apk', fingerprint: true
                archiveArtifacts artifacts: 'build/app/outputs/**/*.aab', fingerprint: true
            }
        }

        // ── 7. Docker Build & Push ──────────────────────────────
        stage('Docker Build & Push') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def imageTag = "${DOCKER_IMAGE}:${BUILD_NUMBER}"
                    def latestTag = "${DOCKER_IMAGE}:latest"

                    withCredentials([usernamePassword(
                        credentialsId: 'docker-registry-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            docker login ${DOCKER_REGISTRY} -u ${DOCKER_USER} -p ${DOCKER_PASS}
                            docker build -t ${imageTag} -t ${latestTag} .
                            docker push ${imageTag}
                            docker push ${latestTag}
                        """
                    }
                }
            }
        }

        // ── 8. Deploy to Kubernetes ─────────────────────────────
        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                withKubeConfig([credentialsId: 'kubeconfig']) {
                    sh """
                        kubectl set image deployment/digitallist-api \
                          digitallist-api=${DOCKER_IMAGE}:${BUILD_NUMBER} \
                          -n ${K8S_NAMESPACE}

                        kubectl rollout status deployment/digitallist-api \
                          -n ${K8S_NAMESPACE} --timeout=5m
                    """
                }
            }
        }
    }

    post {
        success {
            slackSend(
                color: 'good',
                message: "Build ${BUILD_NUMBER} SUCCES - ${APP_NAME} deploye avec succes"
            )
        }
        failure {
            slackSend(
                color: 'danger',
                message: "Build ${BUILD_NUMBER} ECHOUE - ${APP_NAME}"
            )
        }
        always {
            cleanWs()
        }
    }
}
