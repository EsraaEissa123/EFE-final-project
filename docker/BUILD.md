# Build the vProfile Docker image
# Usage: docker build -t vprofile-app:latest .

# Build arguments
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=v2

# Labels
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.version=$VERSION \
      org.label-schema.name="vProfile Application" \
      org.label-schema.description="Multi-tier Java web application" \
      org.label-schema.vendor="Team3"

# Build command:
# docker build \
#   --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
#   --build-arg VCS_REF=$(git rev-parse --short HEAD) \
#   -t vprofile-app:latest \
#   -f Dockerfile .

# Run locally:
# docker run -d -p 8080:8080 --name vprofile vprofile-app:latest

# Push to ECR:
# aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REGISTRY>
# docker tag vprofile-app:latest <ECR_REGISTRY>/vprofile-app:latest
# docker push <ECR_REGISTRY>/vprofile-app:latest
