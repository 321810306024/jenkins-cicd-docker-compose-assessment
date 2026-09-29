pipeline {
    agent any

    environment {
        REPO_ZIP = 'https://github.com/321810306024/jenkins-cicd-docker-compose-assessment/archive/refs/heads/main.zip'

        IMAGE_NAME = 'jenkins-cicd-demo'
        IMAGE_TAG = "${BUILD_NUMBER}"
        CONTAINER_NAME = 'jenkins-cicd-demo'
        HOST_PORT = '8082'
    }

    stages {

        stage('Get Source from GitHub') {
            steps {
                bat '''
                    echo ========================================
                    echo Downloading source from GitHub
                    echo ========================================

                    if exist source.zip del /f /q source.zip
                    if exist _source rmdir /s /q _source

                    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
                    "Invoke-WebRequest -Uri '%REPO_ZIP%' -OutFile 'source.zip'"

                    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
                    "Expand-Archive -Path 'source.zip' -DestinationPath '_source' -Force"

                    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
                    "$d = Get-ChildItem '_source' -Directory | Select-Object -First 1; Copy-Item ($d.FullName + '\\*') '.' -Recurse -Force"

                    del /f /q source.zip
                    rmdir /s /q _source

                    echo Source retrieval successful.
                '''
            }
        }

        stage('Validate Project') {
            steps {
                bat '''
                    echo ========================================
                    echo Validating project
                    echo ========================================

                    if not exist Dockerfile exit /b 1
                    if not exist docker-compose.yml exit /b 1
                    if not exist nginx\\default.conf exit /b 1
                    if not exist app\\index.html exit /b 1
                    if not exist app\\health.html exit /b 1
                    if not exist app\\style.css exit /b 1

                    docker --version
                    docker compose version

                    echo.
                    echo Project validation successful.
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                bat '''
                    echo ========================================
                    echo Building Docker image
                    echo ========================================

                    docker build --pull ^
                        -t %IMAGE_NAME%:%IMAGE_TAG% ^
                        -t %IMAGE_NAME%:latest .

                    echo.
                    echo Docker image build successful.
                '''
            }
        }

        stage('Trivy Security Scan') {
            steps {
                bat '''
                    echo ========================================
                    echo Running Trivy security scan
                    echo ========================================

                    if exist trivy-image.tar del /f /q trivy-image.tar
                    if exist trivy-report.txt del /f /q trivy-report.txt

                    echo Saving Docker image for Trivy...
                    docker save %IMAGE_NAME%:%IMAGE_TAG% -o trivy-image.tar

                    echo Running Trivy...
                    docker run --rm ^
                        -v "%WORKSPACE%:/workspace" ^
                        aquasec/trivy:latest ^
                        image ^
                        --input /workspace/trivy-image.tar ^
                        --severity HIGH,CRITICAL ^
                        --ignore-unfixed ^
                        --format table ^
                        --output /workspace/trivy-report.txt

                    echo.
                    echo ========================================
                    echo Trivy Report
                    echo ========================================

                    type "%WORKSPACE%\\trivy-report.txt"

                    del /f /q trivy-image.tar

                    echo.
                    echo Trivy security scan completed.
                '''
            }
        }

        stage('Deploy with Docker Compose') {
            steps {
                bat '''
                    echo ========================================
                    echo Deploying with Docker Compose
                    echo ========================================

                    set IMAGE_NAME=%IMAGE_NAME%
                    set IMAGE_TAG=%IMAGE_TAG%
                    set CONTAINER_NAME=%CONTAINER_NAME%
                    set HOST_PORT=%HOST_PORT%

                    echo Stopping existing Compose deployment...
                    docker compose down --remove-orphans

                    echo Removing existing container if present...
                    docker rm -f %CONTAINER_NAME% >nul 2>&1

                    echo Starting new deployment...
                    docker compose up -d --build

                    echo.
                    echo Docker Compose deployment completed.
                '''
            }
        }

        stage('Health Check') {
            steps {
                bat '''
                    echo ========================================
                    echo Checking container health
                    echo ========================================

                    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
                    "$healthy=$false; for($i=0;$i -lt 12;$i++){ $status=docker inspect -f '{{.State.Health.Status}}' %CONTAINER_NAME% 2>$null; Write-Host ('Health status: ' + $status); if($status -eq 'healthy'){ $healthy=$true; break }; Start-Sleep -Seconds 5 }; if(-not $healthy){ docker compose logs --tail=100; exit 1 }"

                    echo.
                    echo Container health check passed.
                '''
            }
        }

        stage('Smoke Test') {
            steps {
                bat '''
                    echo ========================================
                    echo Running application smoke test
                    echo ========================================

                    curl.exe --fail --silent http://localhost:%HOST_PORT%/ > nul

                    curl.exe --fail --silent http://localhost:%HOST_PORT%/health

                    echo.
                    echo Application smoke test passed.
                '''
            }
        }

        stage('Archive Trivy Report') {
            steps {
                echo 'Archiving Trivy security report...'

                archiveArtifacts artifacts: 'trivy-report.txt',
                                 fingerprint: true
            }
        }

        stage('Cleanup Old Images') {
            steps {
                bat '''
                    echo ========================================
                    echo Cleaning unused Docker resources
                    echo ========================================

                    docker image prune -f
                    docker builder prune -f

                    echo.
                    echo Docker cleanup completed.
                '''
            }
        }

        stage('Rollback Information') {
            steps {
                echo '''
                Rollback concept:
                Previous Docker image tags are retained by build number.
                If the current deployment fails, the previous known-good
                image can be redeployed using its build tag.
                '''
            }
        }
    }

    post {

        success {
            echo '========================================'
            echo 'CI/CD PIPELINE COMPLETED SUCCESSFULLY'
            echo '========================================'
        }

        failure {
            echo '========================================'
            echo 'PIPELINE FAILED'
            echo 'Check the failed stage and console output.'
            echo '========================================'
        }

        always {
            bat '''
                echo.
                echo ========================================
                echo Final Docker Status
                echo ========================================

                docker image ls %IMAGE_NAME% || exit /b 0

                echo.
                docker compose ps || exit /b 0
            '''
        }
    }
}
