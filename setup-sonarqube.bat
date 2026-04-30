@echo off
REM SonarQube Local Setup Script for Windows
REM This script sets up SonarQube in Docker and connects it to your project

setlocal enabledelayedexpansion

echo.
echo 🚀 SonarQube Local Setup
echo =======================
echo.

REM Configuration
set SONAR_CONTAINER_NAME=sonarqube-vulnerable-app
set SONAR_PORT=9000
set SONAR_DB_PORT=5432
set SONAR_VERSION=latest
set PROJECT_KEY=vulnerable-app
set PROJECT_NAME=Vulnerable App
set SONAR_USER=admin
set SONAR_PASS=admin

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed. Please install Docker first.
    exit /b 1
)

echo ✅ Docker is installed
echo.

REM Check if container already exists
docker ps -a --format "{{.Names}}" | findstr /R "^%SONAR_CONTAINER_NAME%$" >nul 2>&1
if not errorlevel 1 (
    echo ⚠️  SonarQube container already exists
    set /p RECREATE="Do you want to remove and recreate it? (y/n): "
    if /i "!RECREATE!"=="y" (
        echo Stopping and removing existing container...
        docker stop %SONAR_CONTAINER_NAME% >nul 2>&1
        docker rm %SONAR_CONTAINER_NAME% >nul 2>&1
    ) else (
        echo Using existing container...
        docker start %SONAR_CONTAINER_NAME% >nul 2>&1
        echo ✅ SonarQube is running on http://localhost:%SONAR_PORT%
        exit /b 0
    )
)

echo Starting SonarQube container...
echo.

REM Run SonarQube container
docker run -d ^
    --name %SONAR_CONTAINER_NAME% ^
    -p %SONAR_PORT%:9000 ^
    -p %SONAR_DB_PORT%:5432 ^
    -e SONAR_JDBC_URL=jdbc:postgresql://localhost:5432/sonarqube ^
    -e SONAR_JDBC_USERNAME=sonar ^
    -e SONAR_JDBC_PASSWORD=sonar ^
    -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLED=true ^
    -v sonarqube_data:/opt/sonarqube/data ^
    -v sonarqube_extensions:/opt/sonarqube/extensions ^
    -v sonarqube_logs:/opt/sonarqube/logs ^
    sonarqube:%SONAR_VERSION%

echo ✅ SonarQube container started
echo.

REM Wait for SonarQube to be ready
echo Waiting for SonarQube to be ready...
set MAX_ATTEMPTS=60
set ATTEMPT=0

:wait_loop
if %ATTEMPT% geq %MAX_ATTEMPTS% (
    echo ❌ SonarQube failed to start
    exit /b 1
)

curl -s http://localhost:%SONAR_PORT%/api/system/health | findstr /R "UP" >nul 2>&1
if errorlevel 1 (
    set /a ATTEMPT+=1
    echo Attempt !ATTEMPT!/%MAX_ATTEMPTS%...
    timeout /t 2 /nobreak >nul
    goto wait_loop
)

echo ✅ SonarQube is ready
echo.

echo 🔐 Configuring SonarQube...
echo.

REM Create project
echo Creating SonarQube project...
curl -X POST "http://localhost:%SONAR_PORT%/api/projects/create" ^
    -u %SONAR_USER%:%SONAR_PASS% ^
    -d "project=%PROJECT_KEY%&name=%PROJECT_NAME%" ^
    2>nul

echo.
echo ✅ SonarQube Configuration Complete
echo.
echo 📊 SonarQube Dashboard:
echo    URL: http://localhost:%SONAR_PORT%
echo    Username: %SONAR_USER%
echo    Password: %SONAR_PASS%
echo.
echo 🔑 Generate Authentication Token:
echo    1. Go to http://localhost:%SONAR_PORT%
echo    2. Login with admin/admin
echo    3. Click on your profile (top right)
echo    4. Select 'My Account' → 'Security'
echo    5. Generate a token
echo.
echo 📝 Run SonarQube Scanner:
echo    npm run sonar
echo.
echo 🛑 Stop SonarQube:
echo    docker stop %SONAR_CONTAINER_NAME%
echo.
echo 🗑️  Remove SonarQube:
echo    docker rm %SONAR_CONTAINER_NAME%
echo    docker volume rm sonarqube_data sonarqube_extensions sonarqube_logs
echo.

endlocal
