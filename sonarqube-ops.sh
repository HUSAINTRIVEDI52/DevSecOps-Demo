#!/bin/bash

# SonarQube Operations Guide
# Comprehensive commands for managing SonarQube locally

set -e

CONTAINER_NAME="sonarqube-vulnerable-app"
SONAR_PORT=9000
SONAR_USER="admin"
SONAR_PASS="admin"
PROJECT_KEY="vulnerable-app"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to start SonarQube
start_sonarqube() {
    print_header "Starting SonarQube"

    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_success "SonarQube is already running"
        return 0
    fi

    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_info "Starting existing container..."
        docker start $CONTAINER_NAME
        print_success "Container started"
    else
        print_info "Creating new container with Docker Compose..."
        docker-compose up -d
        print_success "Container created and started"
    fi

    # Wait for SonarQube
    print_info "Waiting for SonarQube to be ready..."
    for i in {1..60}; do
        if curl -s http://localhost:$SONAR_PORT/api/system/health | grep -q '"status":"UP"'; then
            print_success "SonarQube is ready"
            return 0
        fi
        echo "Attempt $i/60..."
        sleep 2
    done

    print_error "SonarQube failed to start"
    return 1
}

# Function to stop SonarQube
stop_sonarqube() {
    print_header "Stopping SonarQube"

    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        docker stop $CONTAINER_NAME
        print_success "SonarQube stopped"
    else
        print_info "SonarQube is not running"
    fi
}

# Function to restart SonarQube
restart_sonarqube() {
    print_header "Restarting SonarQube"
    stop_sonarqube
    sleep 2
    start_sonarqube
}

# Function to view logs
view_logs() {
    print_header "SonarQube Logs"
    docker logs -f $CONTAINER_NAME
}

# Function to run scanner
run_scanner() {
    print_header "Running SonarQube Scanner"

    if ! command -v sonar-scanner &> /dev/null; then
        print_error "sonar-scanner is not installed"
        print_info "Install with: npm install -g sonarqube-scanner"
        return 1
    fi

    print_info "Scanning project..."
    sonar-scanner \
        -Dsonar.projectKey=$PROJECT_KEY \
        -Dsonar.sources=. \
        -Dsonar.host.url=http://localhost:$SONAR_PORT \
        -Dsonar.login=$SONAR_USER \
        -Dsonar.password=$SONAR_PASS \
        -Dsonar.exclusions=node_modules/**,test/**,.git/**,.github/**,coverage/**

    print_success "Scan completed"
}

# Function to generate token
generate_token() {
    print_header "Generating Authentication Token"

    print_info "Creating token..."
    TOKEN=$(curl -s -X POST "http://localhost:$SONAR_PORT/api/user_tokens/generate" \
        -u $SONAR_USER:$SONAR_PASS \
        -d "name=vulnerable-app-token" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

    if [ -z "$TOKEN" ]; then
        print_error "Failed to generate token"
        return 1
    fi

    print_success "Token generated: $TOKEN"
    echo "Save this token securely!"
}

# Function to get project status
get_project_status() {
    print_header "Project Status"

    print_info "Fetching project metrics..."
    curl -s -u $SONAR_USER:$SONAR_PASS \
        "http://localhost:$SONAR_PORT/api/measures/component?component=$PROJECT_KEY&metricKeys=bugs,vulnerabilities,code_smells,coverage,duplicated_lines_density" | \
        jq '.' 2>/dev/null || echo "Could not fetch metrics"
}

# Function to get quality gate status
get_quality_gate() {
    print_header "Quality Gate Status"

    print_info "Fetching quality gate status..."
    curl -s -u $SONAR_USER:$SONAR_PASS \
        "http://localhost:$SONAR_PORT/api/qualitygates/project_status?projectKey=$PROJECT_KEY" | \
        jq '.' 2>/dev/null || echo "Could not fetch quality gate status"
}

# Function to clean up
cleanup() {
    print_header "Cleaning Up"

    read -p "Remove SonarQube container and volumes? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Stopping container..."
        docker-compose down -v
        print_success "Cleanup complete"
    else
        print_info "Cleanup cancelled"
    fi
}

# Function to show dashboard
show_dashboard() {
    print_header "SonarQube Dashboard"

    print_info "Opening SonarQube dashboard..."
    echo ""
    echo "URL: http://localhost:$SONAR_PORT"
    echo "Username: $SONAR_USER"
    echo "Password: $SONAR_PASS"
    echo ""

    # Try to open in browser
    if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:$SONAR_PORT" 2>/dev/null || true
    elif command -v open &> /dev/null; then
        open "http://localhost:$SONAR_PORT" 2>/dev/null || true
    fi
}

# Function to show help
show_help() {
    cat << EOF
${BLUE}SonarQube Operations Guide${NC}

Usage: ./sonarqube-ops.sh [COMMAND]

Commands:
    start           Start SonarQube container
    stop            Stop SonarQube container
    restart         Restart SonarQube container
    logs            View SonarQube logs
    scan            Run SonarQube scanner
    token           Generate authentication token
    status          Get project status
    quality-gate    Get quality gate status
    dashboard       Open SonarQube dashboard
    cleanup         Remove SonarQube and volumes
    help            Show this help message

Examples:
    ./sonarqube-ops.sh start
    ./sonarqube-ops.sh scan
    ./sonarqube-ops.sh status
    ./sonarqube-ops.sh logs

EOF
}

# Main
case "${1:-help}" in
    start)
        start_sonarqube
        ;;
    stop)
        stop_sonarqube
        ;;
    restart)
        restart_sonarqube
        ;;
    logs)
        view_logs
        ;;
    scan)
        start_sonarqube && run_scanner
        ;;
    token)
        start_sonarqube && generate_token
        ;;
    status)
        start_sonarqube && get_project_status
        ;;
    quality-gate)
        start_sonarqube && get_quality_gate
        ;;
    dashboard)
        start_sonarqube && show_dashboard
        ;;
    cleanup)
        cleanup
        ;;
    help)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
