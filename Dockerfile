# Multi-Stage Dockerfile for vProfile Java Application
# Stage 1: Build the application with Maven

FROM maven:3.8-openjdk-11-slim AS builder

LABEL maintainer="Team3 DevOps"
LABEL description="vProfile Application Build Stage"

# Set working directory
WORKDIR /app

# Copy pom.xml first for dependency caching
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Verify the WAR file was created
RUN ls -lh /app/target/*.war

# Stage 2: Runtime stage with Tomcat

FROM tomcat:9-jre11-slim

LABEL maintainer="Team3 DevOps"
LABEL description="vProfile Application Runtime"

# Remove default Tomcat webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR file from builder stage
COPY --from=builder /app/target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

# Create non-root user
RUN groupadd -r vprofile && useradd -r -g vprofile -u 1001 vprofile

# Create necessary directories with correct permissions
RUN mkdir -p /usr/local/tomcat/temp /usr/local/tomcat/work && \
  chown -R vprofile:vprofile /usr/local/tomcat

# Security: Remove unnecessary packages and update
# Note: Removed apt update/upgrade as Debian Stretch is EOL
# Consider switching to a newer Tomcat base image in production

# Switch to non-root user
USER vprofile

# Expose Tomcat port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

# Start Tomcat
CMD ["catalina.sh", "run"]
