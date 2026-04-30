#!/bin/bash

# SonarQube Local Setup Script
# This script sets up SonarQube in Docker and connects it to your project

set -e

echo "🚀 SonarQube Local Setup"
echo "======================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SONAR_CONTAINER_NAME="sonarqube-vulnerable-app"
SONAR_PORT=9000
SONAR_DB_PORT=5432
SONAR_VERSION="latest"
PROJECT_KEY="vulnerable-app"
PROJECT_NAME="Vulnerable App"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker is installed${NC}"
echo ""

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^${SONAR_CONTAINER_NAME}$"; then
    echo -e "${YELLOW}⚠️  SonarQube container already exists${NC}"
    read -p "Do you want to remove and recreate it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping and removing existing container..."
        docker stop $SONAR_CONTAINER_NAME 2>/dev/null || true
        docker rm $SONAR_CONTAINER_NAME 2>/dev/null || true
    else
        echo "Using existing container..."
        docker start $SONAR_CONTAINER_NAME 2>/dev/null || true
        echo -e "${GREEN}✅ SonarQube is running on http://localhost:${SONAR_PORT}${NC}"
        exit 0
    fi
fi

echo "Starting SonarQube container..."
echo ""

# Run SonarQube container
docker run -d \
    --name $SONAR_CONTAINER_NAME \
    -p $SONAR_PORT:9000 \
    -p $SONAR_DB_PORT:5432 \
    -e SONAR_JDBC_URL=jdbc:postgresql://localhost:5432/sonarqube \
    -e SONAR_JDBC_USERNAME=sonar \
    -e SONAR_JDBC_PASSWORD=sonar \
    -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLED=true \
    -v sonarqube_data:/opt/sonarqube/data \
    -v sonarqube_extensions:/opt/sonarqube/extensions \
    -v sonarqube_logs:/opt/sonarqube/logs \
    sonarqube:$SONAR_VERSION

echo -e "${GREEN}✅ SonarQube container started${NC}"
echo ""

# Wait for SonarQube to be ready
echo "Waiting for SonarQube to be ready..."
MAX_ATTEMPTS=60
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s http://localhost:$SONAR_PORT/api/system/health | grep -q '"status":"UP"'; then
        echo -e "${GREEN}✅ SonarQube is ready${NC}"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    echo "Attempt $ATTEMPT/$MAX_ATTEMPTS..."
    sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo -e "${RED}❌ SonarQube failed to start${NC}"
    exit 1
fi

echo ""
echo "🔐 Configuring SonarQube..."
echo ""

# Default credentials
SONAR_USER="admin"
SONAR_PASS="admin"

# Create project
echo "Creating SonarQube project..."
curl -X POST "http://localhost:$SONAR_PORT/api/projects/create" \
    -u $SONAR_USER:$SONAR_PASS \
    -d "project=$PROJECT_KEY&name=$PROJECT_NAME" \
    2>/dev/null || echo "Project may already exist"

echo ""
echo -e "${GREEN}✅ SonarQube Configuration Complete${NC}"
echo ""
echo "📊 SonarQube Dashboard:"
echo "   URL: http://localhost:$SONAR_PORT"
echo "   Username: $SONAR_USER"
echo "   Password: $SONAR_PASS"
echo ""
echo "🔑 Generate Authentication Token:"
echo "   1. Go to http://localhost:$SONAR_PORT"
echo "   2. Login with admin/admin"
echo "   3. Click on your profile (top right)"
echo "   4. Select 'My Account' → 'Security'"
echo "   5. Generate a token"
echo ""
echo "📝 Run SonarQube Scanner:"
echo "   npm run sonar"
echo ""
echo "🛑 Stop SonarQube:"
echo "   docker stop $SONAR_CONTAINER_NAME"
echo ""
echo "🗑️  Remove SonarQube:"
echo "   docker rm $SONAR_CONTAINER_NAME"
echo "   docker volume rm sonarqube_data sonarqube_extensions sonarqube_logs"
echo ""
