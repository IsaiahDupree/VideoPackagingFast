@echo off
REM ========================================================
REM VideoPackagingFast - Installation Logger Helper
REM ========================================================
REM This script provides enhanced logging functionality
REM for the one-click installation process

:log
    set "LOG_LEVEL=%~1"
    set "LOG_MESSAGE=%~2"
    set "LOG_FILE=%~3"
    
    REM Format timestamp
    for /f "tokens=1-4 delims=/ " %%a in ('date /t') do set "DATE=%%a/%%b/%%c"
    for /f "tokens=1-3 delims=: " %%a in ('time /t') do set "TIME=%%a:%%b:%%c"
    
    REM Format log entry
    set "LOG_ENTRY=[%DATE% %TIME%] [%LOG_LEVEL%] %LOG_MESSAGE%"
    
    REM Display to console with color coding based on log level
    if "%LOG_LEVEL%"=="INFO" (
        echo [INFO] %LOG_MESSAGE%
    ) else if "%LOG_LEVEL%"=="WARNING" (
        echo [33m[WARNING] %LOG_MESSAGE%[0m
    ) else if "%LOG_LEVEL%"=="ERROR" (
        echo [31m[ERROR] %LOG_MESSAGE%[0m
    ) else if "%LOG_LEVEL%"=="SUCCESS" (
        echo [32m[SUCCESS] %LOG_MESSAGE%[0m
    ) else (
        echo %LOG_MESSAGE%
    )
    
    REM Write to log file
    echo %LOG_ENTRY% >> "%LOG_FILE%"
    
    exit /b 0

:capture_command
    REM Executes a command and captures its output to the log file
    REM Usage: call :capture_command "Command" "Description" "LogFile"
    
    set "COMMAND=%~1"
    set "DESCRIPTION=%~2"
    set "LOG_FILE=%~3"
    
    REM Log the command being executed
    call :log "INFO" "Executing: %DESCRIPTION%" "%LOG_FILE%"
    echo ^> %COMMAND% >> "%LOG_FILE%"
    
    REM Execute the command and capture output
    %COMMAND% >> "%LOG_FILE%" 2>&1
    set "RESULT=%ERRORLEVEL%"
    
    REM Log the result
    if %RESULT% EQU 0 (
        call :log "INFO" "%DESCRIPTION% completed successfully" "%LOG_FILE%"
    ) else (
        call :log "ERROR" "%DESCRIPTION% failed with error code %RESULT%" "%LOG_FILE%"
    )
    
    exit /b %RESULT%

:check_dependency
    REM Checks if a dependency is available and logs the result
    REM Usage: call :check_dependency "Command" "DependencyName" "LogFile"
    
    set "CHECK_COMMAND=%~1"
    set "DEPENDENCY_NAME=%~2"
    set "LOG_FILE=%~3"
    
    call :log "INFO" "Checking for %DEPENDENCY_NAME%..." "%LOG_FILE%"
    %CHECK_COMMAND% >> "%LOG_FILE%" 2>&1
    
    if %ERRORLEVEL% EQU 0 (
        call :log "INFO" "%DEPENDENCY_NAME% is available" "%LOG_FILE%"
        exit /b 0
    ) else (
        call :log "WARNING" "%DEPENDENCY_NAME% is not available" "%LOG_FILE%"
        exit /b 1
    )

:log_system_info
    REM Logs system information to help with debugging
    REM Usage: call :log_system_info "LogFile"
    
    set "LOG_FILE=%~1"
    
    call :log "INFO" "Collecting system information..." "%LOG_FILE%"
    echo ===== SYSTEM INFORMATION ===== >> "%LOG_FILE%"
    
    echo OS Version: >> "%LOG_FILE%"
    ver >> "%LOG_FILE%" 2>&1
    
    echo System Architecture: >> "%LOG_FILE%"
    wmic os get osarchitecture >> "%LOG_FILE%" 2>&1
    
    echo Available RAM: >> "%LOG_FILE%"
    wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /Value >> "%LOG_FILE%" 2>&1
    
    echo Available Disk Space: >> "%LOG_FILE%"
    wmic logicaldisk where "DeviceID='%SystemDrive%'" get Size,FreeSpace /Value >> "%LOG_FILE%" 2>&1
    
    echo Internet Connectivity: >> "%LOG_FILE%"
    ping -n 2 -w 1000 8.8.8.8 >> "%LOG_FILE%" 2>&1
    
    echo ===== END SYSTEM INFORMATION ===== >> "%LOG_FILE%"
    
    exit /b 0
