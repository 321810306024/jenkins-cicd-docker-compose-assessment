pipeline {
    agent any

    environment {
        IMAGE_NAME = 'jenkins-cicd-demo'
        IMAGE_TAG = "${BUILD_NUMBER}"
        CONTAINER_NAME = 'jenkins-cicd-demo'
        HOST_PORT = '8082'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate Project') {
            steps {
                bat '''
                    echo Checking project files...

                    if not exist Dockerfile exit /b 1
                    if not exist docker-compose.yml exit /b 1
                    if not exist nginx\\default.conf exit /b 1
                    if not exist app\\index.html exit /b 1
                    if not exist app\\health.html exit /b 1

                    docker --version
                    docker compose version

                    echo Project validation successful.
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                bat '''
                    docker build --pull ^
                        -t %IMAGE_NAME%:%IMAGE_TAG% ^
                        -t %IMAGE_NAME%:latest .
                '''
            }
        }

        stage('Trivy Security Scan') {
            steps {
                bat '''
                    trivy image ^
                        --severity HIGH,CRITICAL ^
                        --ignore-unfixed ^
                        --format table ^
                        --output "%WORKSPACE%\\trivy-report.txt" ^
                        %IMAGE_NAME%:%IMAGE_TAG%

                    type "%WORKSPACE%\\trivy-report.txt"
                '''
            }
        }

        stage('Deploy with Docker Compose') {
            steps {
                bat '''
                    set IMAGE_NAME=%IMAGE_NAME%
                    set IMAGE_TAG=%IMAGE_TAG%
                    set CONTAINER_NAME=%CONTAINER_NAME%
                    set HOST_PORT=%HOST_PORT%

                    docker compose down
                    docker compose up -d --build
                '''
            }
        }

        stage('Health Check') {
            steps {
                bat '''
                    echo Waiting for container health...

                    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
                    "$healthy=$false; for($i=0;$i -lt 12;$i++){ $status=docker inspect -f '{{.State.Health.Status}}' %CONTAINER_NAME% 2>$null; Write-Host ('Health status: ' + $status); if($status -eq 'healthy'){ $healthy=$true; break }; Start-Sleep -Seconds 5 }; if(-not $healthy){ docker compose logs --tail=100; exit 1 }"

                    echo Health check passed.
                '''
            }
        }

        stage('Smoke Test') {
            steps {
                bat '''
                    curl.exe --fail --silent http://localhost:%HOST_PORT%/ > nul
                    curl.exe --fail --silent http://localhost:%HOST_PORT%/health
                    echo.
                    echo Smoke test passed.
                '''
            }
        }

        stage('Archive Trivy Report') {
            steps {
                archiveArtifacts artifacts: 'trivy-report.txt', fingerprint: true
            }
        }

        stage('Cleanup Old Images') {
            steps {
                bat '''
                    docker image prune -f
                    docker builder prune -f
                '''
            }
        }
    }

    post {
        success {
            echo 'CI/CD pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the failed stage and console output.'
        }

        always {
            bat '''
                docker image ls %IMAGE_NAME% || exit /b 0
                docker compose ps || exit /b 0
            '''
        }
    }
}