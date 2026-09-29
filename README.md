# Jenkins CI/CD Pipeline with Docker Compose

## 1. Project Overview

This assessment uses one frontend-only static web application. There is no backend, API, database, or external service.

Technology stack:
- Git
- Jenkins
- Docker
- Docker Compose
- Nginx
- Trivy

The Jenkins pipeline performs:
1. Git checkout
2. Project validation
3. Docker image build
4. Trivy HIGH/CRITICAL vulnerability scan
5. Docker Compose deployment
6. Container health check
7. HTTP smoke test
8. Trivy report archival
9. Docker image/builder cleanup

## 2. Project Structure

```text
jenkins-cicd-docker-compose-assessment/
├── app/
│   ├── index.html
│   ├── style.css
│   └── health.html
├── nginx/
│   └── default.conf
├── Dockerfile
├── docker-compose.yml
├── Jenkinsfile
├── .env.example
├── .dockerignore
├── .gitignore
└── README.md
```

## 3. Run Locally

Copy `.env.example` to `.env` if environment customization is required.

Build and start:

```bash
docker compose build
docker compose up -d
```

Check:

```bash
docker compose ps
curl http://localhost:8080/
curl http://localhost:8080/health
```

Open:

```text
http://localhost:8080
```

View logs:

```bash
docker compose logs -f frontend
```

Stop:

```bash
docker compose down
```

The named `nginx_logs` volume is intentionally retained when `docker compose down` is used, so logs remain persistent.

## 4. Environment Configuration

The `.env.example` file contains:

```text
APP_ENV=production
IMAGE_NAME=jenkins-cicd-demo
IMAGE_TAG=latest
CONTAINER_NAME=jenkins-cicd-demo
HOST_PORT=8080
VOLUME_NAME=jenkins_cicd_nginx_logs
```

Do not commit real secrets. This project does not require any secrets.

## 5. Jenkins Requirements

The Jenkins agent must have:
- Git
- Docker
- Docker Compose v2
- curl
- Trivy

Jenkins must be allowed to execute Docker commands.

Recommended Jenkins credentials:
- Git credentials/token if the repository is private

The pipeline uses `checkout scm`, so it works naturally with a Jenkins Pipeline job connected to the Git repository.

## 6. Jenkins Pipeline Flow

```text
Git Repository
      |
      v
Jenkins Checkout
      |
      v
Validate files/tools
      |
      v
Docker Build
      |
      v
Trivy HIGH/CRITICAL Scan
      |
      v
Docker Compose Deploy
      |
      v
Container Health Check
      |
      v
HTTP Smoke Test
      |
      v
Archive Trivy Report
      |
      v
Cleanup unused Docker data
```

## 7. Trivy Security Scan

The Jenkinsfile runs:

```bash
trivy image   --format table   --output trivy-report.txt   --severity HIGH,CRITICAL   --ignore-unfixed   jenkins-cicd-demo:<build-number>
```

The report is archived as a Jenkins build artifact.

For a stricter security gate, the pipeline can later use `--exit-code 1` so that HIGH/CRITICAL findings fail the build.

## 8. Health Check

The container exposes:

```text
GET /health
```

Expected response:

```text
OK
```

Docker Compose also defines a health check. Jenkins waits until Docker reports the container as `healthy`.

## 9. Persistent Storage

Nginx access and error logs are stored in:

```text
jenkins_cicd_nginx_logs
```

This named Docker volume is mounted at:

```text
/var/log/nginx
```

This demonstrates persistent storage without introducing a backend/database.

Check the volume:

```bash
docker volume ls
```

## 10. Cleanup

The pipeline performs:

```bash
docker image prune -f
docker builder prune -f
```

This removes unused Docker images/build cache while leaving the currently running deployment intact.

## 11. Rollback Concept

Each Jenkins build creates an immutable image tag:

```text
jenkins-cicd-demo:BUILD_NUMBER
```

Example:

```text
jenkins-cicd-demo:25
jenkins-cicd-demo:26
```

If build 26 is deployed and a problem is discovered, rollback means deploying the last known-good image, for example build 25.

Example manual rollback:

```bash
export IMAGE_NAME=jenkins-cicd-demo
export IMAGE_TAG=25
export CONTAINER_NAME=jenkins-cicd-demo
export HOST_PORT=8080
export VOLUME_NAME=jenkins_cicd_nginx_logs

docker compose down
docker compose up -d --no-build
```

The important point is that rollback uses a previous immutable image tag rather than rebuilding the old source code.

## 12. Required Assessment Screenshots

Capture these screenshots for submission:

1. Git repository showing project files
2. Jenkins job configuration showing Git repository
3. Jenkins pipeline build stages
4. Successful Docker image build
5. Trivy scan and generated report
6. `docker compose ps` showing healthy container
7. Browser showing `http://localhost:8080`
8. `curl http://localhost:8080/health` showing `OK`
9. Docker volume using `docker volume ls`
10. Docker image tags showing build-number versioning
11. Successful Jenkins build console output
12. Optional rollback demonstration using a previous image tag

## 13. Sample Deployment Evidence

Useful commands:

```bash
docker compose ps
docker image ls jenkins-cicd-demo
docker volume ls
docker inspect jenkins-cicd-demo
curl -i http://localhost:8080/health
docker compose logs --tail=50 frontend
```

## 14. Assessment Explanation

The project demonstrates a complete basic CI/CD workflow for a frontend application. Jenkins obtains the source code from Git, validates the project, builds a Docker image, scans the image with Trivy, and deploys the image using Docker Compose.

The deployment includes Docker health checks and an HTTP smoke test so that Jenkins can verify that the application is actually responding after deployment. Nginx logs are stored in a named Docker volume to demonstrate persistent storage.

Environment values are externalized through `.env`/Compose variables instead of hard-coding deployment configuration. Build-number image tags provide traceability and make rollback possible because previous images can be redeployed without rebuilding.

The pipeline also performs cleanup of unused Docker images and builder cache after a successful deployment.

## 15. Important Note

This is intentionally a single frontend-only project. No backend service is required for the assessment.
