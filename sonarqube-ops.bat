@echo off
REM SonarQube Operations Guide for Windows
REM Comprehensive commands for managing SonarQube locally

setlocal enabledelayedexpansion

set CONTAINER_NAME=sonarqube-vulnerable-app
set SONAR_PORT=9000
set SONAR_USER=admin
set SONAR_PASS=admin
set PROJECT_KEY=vulnerable-app

REM Colors (using ANSI escape codes)
set GREEN=[32m
set RED=[31m
set YELLOW=[33m
set BLUE=[34m
set RESET=[0m

:main
if "%1"=="" (
    call :show_help
    exit /b 0
)

if /i "%1"=="start" (
    call :start_sonarqube
    exit /b !errorlevel!
)

if /i "%1"=="stop" (
    call :stop_sonarqube
    exit /b !errorlevel!
)

if /i "%1"=="restart" (
    call :restart_sonarqube
    exit /b !errorlevel!
)

if /i "%1"=="logs" (
    call :view_logs
    exit /b !errorlevel!
)

if /i "%1"=="scan" (
    call :start_sonarqube
    if !errorlevel! equ 0 call :run_scanner
    exit /b !errorlevel!
)

if /i "%1"=="status" (
    call :start_sonarqube
    if !errorlevel! equ 0 call :get_project_status
    exit /b !errorlevel!
)

if /i "%1"=="dashboard" (
    call :start_sonarqube
    if !errorlevel! equ 0 call :show_dashboard
    exit /b !errorlevel!
)

if /i "%1"=="cleanup" (
    call :cleanup
    exit /b !errorlevel!
)

if /i "%1"=="help" (
    call :show_help
    exit /b 0
)

echo Unknown command: %1
call :show_help
exit /b 1

:start_sonarqube
echo.
echo Starting SonarQube...
echo.

docker ps --format "{{.Names}}" | findstr /R "^%CONTAINER_NAME%$" >nul 2>&1
if not errorlevel 1 (
    echo SonarQube is already running
    exit /b 0
)

docker ps -a --format "{{.Names}}" | findstr /R "^%CONTAINER_NAME%$" >nul 2>&1
if not errorlevel 1 (
    echo Starting existing container...
    docker start %CONTAINER_NAME%
    echo Container started
) else (
    echo Creating new container with Docker Compose...
    docker-compose up -d
    echo Container created and started
)

echo Waiting for SonarQube to be ready...
set ATTEMPT=0
:wait_loop
if %ATTEMPT% geq 60 (
    echo SonarQube failed to start
    exit /b 1
)

curl -s http://localhost:%SONAR_PORT%/api/system/health | findstr /R "UP" >nul 2>&1
if errorlevel 1 (
    set /a ATTEMPT+=1
    echo Attempt !ATTEMPT!/60...
    timeout /t 2 /nobreak >nul
    goto wait_loop
)

echo SonarQube is ready
exit /b 0

:stop_sonarqube
echo.
echo Stopping SonarQube...
echo.

docker ps --format "{{.Names}}" | findstr /R "^%CONTAINER_NAME%$" >nul 2>&1
if not errorlevel 1 (
    docker stop %CONTAINER_NAME%
    echo SonarQube stopped
) else (
    echo SonarQube is not running
)

exit /b 0

:restart_sonarqube
echo.
echo Restarting SonarQube...
echo.

call :stop_sonarqube
timeout /t 2 /nobreak >nul
call :start_sonarqube
exit /b !errorlevel!

:view_logs
echo.
echo SonarQube Logs
echo.

docker logs -f %CONTAINER_NAME%
exit /b 0

:run_scanner
echo.
echo Running SonarQube Scanner...
echo.

where sonar-scanner >nul 2>&1
if errorlevel 1 (
    echo sonar-scanner is not installed
    echo Install with: npm install -g sonarqube-scanner
    exit /b 1
)

sonar-scanner ^
    -Dsonar.projectKey=%PROJECT_KEY% ^
    -Dsonar.sources=. ^
    -Dsonar.host.url=http://localhost:%SONAR_PORT% ^
    -Dsonar.login=%SONAR_USER% ^
    -Dsonar.password=%SONAR_PASS% ^
    -Dsonar.exclusions=node_modules/**,test/**,.git/**,.github/**,coverage/**

echo Scan completed
exit /b 0

:get_project_status
echo.
echo Project Status
echo.

echo Fetching project metrics...
curl -s -u %SONAR_USER%:%SONAR_PASS% ^
    "http://localhost:%SONAR_PORT%/api/measures/component?component=%PROJECT_KEY%&metricKeys=bugs,vulnerabilities,code_smells,coverage,duplicated_lines_density"

exit /b 0

:show_dashboard
echo.
echo SonarQube Dashboard
echo.

echo URL: http://localhost:%SONAR_PORT%
echo Username: %SONAR_USER%
echo Password: %SONAR_PASS%
echo.

start http://localhost:%SONAR_PORT%
exit /b 0

:cleanup
echo.
echo Cleaning Up
echo.

set /p CONFIRM="Remove SonarQube container and volumes? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo Cleanup cancelled
    exit /b 0
)

echo Stopping and removing containers...
docker-compose down -v
echo Cleanup complete
exit /b 0

:show_help
echo.
echo SonarQube Operations Guide
echo.
echo Usage: sonarqube-ops.bat [COMMAND]
echo.
echo Commands:
echo    start           Start SonarQube container
echo    stop            Stop SonarQube container
echo    restart         Restart SonarQube container
echo    logs            View SonarQube logs
echo    scan            Run SonarQube scanner
echo    status          Get project status
echo    dashboard       Open SonarQube dashboard
echo    cleanup         Remove SonarQube and volumes
echo    help            Show this help message
echo.
echo Examples:
echo    sonarqube-ops.bat start
echo    sonarqube-ops.bat scan
echo    sonarqube-ops.bat status
echo    sonarqube-ops.bat logs
echo.

exit /b 0

endlocal
