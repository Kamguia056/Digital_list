pipeline {
    agent none

    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('firebase-service-account')
    }

    stages {
        stage('Checkout') {
            agent any
            steps {
                checkout scm
                stash includes: '**', name: 'source', useDefaultExcludes: false
            }
        }

        stage('Build') {
            agent {
                docker { image 'ghcr.io/cirruslabs/flutter:3.29.0' args '-u root:root' }
            }
            steps {
                unstash 'source'
                sh 'flutter pub get'
                sh 'flutter build apk --release'
                stash includes: 'build/app/outputs/flutter-apk/app-release.apk', name: 'apk'
            }
        }

        stage('Test') {
            agent {
                docker { image 'ghcr.io/cirruslabs/flutter:3.29.0' args '-u root:root' }
            }
            steps {
                unstash 'source'
                sh 'flutter pub get'
                sh 'flutter test'
            }
        }

        stage('Deploy - Firebase App Distribution') {
            agent {
                docker { image 'node:20-bullseye' args '-u root:root' }
            }
            steps {
                unstash 'source'
                unstash 'apk'
                sh '''
                npm install -g firebase-tools
                firebase appdistribution:distribute \
                  build/app/outputs/flutter-apk/app-release.apk \
                  --app YOUR_FIREBASE_APP_ID \
                  --groups "testers"
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline terminé avec succès ✅'
        }
        failure {
            echo 'Le pipeline a échoué ❌'
        }
    }
}
