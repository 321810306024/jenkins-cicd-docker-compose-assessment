# Multi-stage Dockerfile for a static frontend
FROM nginx:1.27-alpine AS runtime

LABEL org.opencontainers.image.title="jenkins-cicd-demo"
LABEL org.opencontainers.image.description="Frontend-only CI/CD assessment project"

COPY app/ /usr/share/nginx/html/

# Custom health endpoint
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3   CMD wget -q -O - http://127.0.0.1/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
