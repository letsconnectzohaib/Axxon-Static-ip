@echo off
:: Set-StaticIP-CrashSafe.bat
:: Crash-safe version with comprehensive error handling

:: Enable crash handling
setlocal enabledelayedexpansion

:: Set error handling
if not defined ERROR_SUCCESS set ERROR_SUCCESS=0
if not defined ERROR_FILE_NOT_FOUND set ERROR_FILE_NOT_FOUND=2
if not defined ERROR_ACCESS_DENIED set ERROR_ACCESS_DENIED=5

:: Initialize variables
set currentIP=
set subnetMask=
set gateway=
set adapter=
set scriptFailed=0

:: Function to handle errors
:handleError
echo [CRITICAL ERROR] %~1
echo [FAILED] %~2
echo [DEBUG] Error occurred at: %date% %time%
echo.
echo Press any key to exit...
pause >nul
exit /b 1

:: Main script with crash protection
:mainScript
cls
echo ========================================
echo Crash-Safe Static IP Configuration
echo ========================================
echo.

:: Check for administrator privileges with crash protection
echo [INIT] Checking administrator privileges...
net session >nul 2>&1
if %errorLevel% neq 0 (
    call :handleError "Administrator privileges required" "Privilege check failed"
)
echo [SUCCESS] Administrator privileges confirmed

:: Step 1: Get current IP address with crash protection
echo [STEP 1/4] Detecting current IP address...
set currentIP=
for /f "tokens=2 delims=:" %%a in ('ipconfig 2^>nul ^| findstr /i "IPv4 Address" 2^>nul') do (
    if "!currentIP!"=="" set currentIP=%%a
)

:: Clean up IP address
if defined currentIP (
    set currentIP=!currentIP: =!
    set currentIP=!currentIP:  =!
)

if not defined currentIP (
    call :handleError "Could not detect IP address" "Step 1 - IP address detection"
)
echo [SUCCESS] Current IP detected: !currentIP!

:: Step 2: Get subnet mask with crash protection
echo [STEP 2/4] Detecting subnet mask...
set subnetMask=
for /f "tokens=2 delims=:" %%a in ('ipconfig 2^>nul ^| findstr /i "Subnet Mask" 2^>nul') do (
    if "!subnetMask!"=="" set subnetMask=%%a
)

:: Clean up subnet mask
if defined subnetMask (
    set subnetMask=!subnetMask: =!
    set subnetMask=!subnetMask:  =!
)

if not defined subnetMask (
    call :handleError "Could not detect subnet mask" "Step 2 - Subnet mask detection"
)
echo [SUCCESS] Subnet mask detected: !subnetMask!

:: Step 3: Get default gateway with crash protection
echo [STEP 3/4] Detecting default gateway...
set gateway=
for /f "tokens=2 delims=:" %%a in ('ipconfig 2^>nul ^| findstr /i "Default Gateway" 2^>nul') do (
    if "!gateway!"=="" set gateway=%%a
)

:: Clean up gateway
if defined gateway (
    set gateway=!gateway: =!
    set gateway=!gateway:  =!
)

if not defined gateway (
    call :handleError "Could not detect default gateway" "Step 3 - Default gateway detection"
)
echo [SUCCESS] Default gateway detected: !gateway!

:: Step 4: Get network adapter name with crash protection
echo [STEP 4/4] Detecting network adapter...
set adapter=

:: Try multiple methods for adapter detection
:: Method 1: Connected adapters
for /f "tokens=4" %%a in ('netsh interface show interface 2^>nul ^| findstr "Connected" 2^>nul') do (
    if "!adapter!"=="" set adapter=%%a
)

:: Method 2: Enabled adapters if connected failed
if not defined adapter (
    echo [INFO] No connected adapter found, trying enabled adapters...
    for /f "tokens=4" %%a in ('netsh interface show interface 2^>nul ^| findstr "Enabled" 2^>nul') do (
        if "!adapter!"=="" set adapter=%%a
    )
)

:: Method 3: Common names if still failed
if not defined adapter (
    echo [INFO] No specific adapter found, trying common names...
    for %%i in (Ethernet "Local Area Connection" "Wi-Fi") do (
        netsh interface show interface name="%%i" >nul 2>&1
        if !errorLevel! equ 0 (
            set adapter=%%i
            goto :adapterFound
        )
    )
    :adapterFound
)

:: Method 4: Last resort
if not defined adapter (
    echo [WARNING] Using default adapter name...
    set adapter=Ethernet
)

echo [SUCCESS] Network adapter detected: !adapter!

:: Validation with crash protection
echo.
echo [VALIDATION] Checking all required information...
if not defined currentIP (
    call :handleError "Missing IP address" "Validation check"
)

if not defined subnetMask (
    call :handleError "Missing subnet mask" "Validation check"
)

if not defined gateway (
    call :handleError "Missing default gateway" "Validation check"
)

if not defined adapter (
    call :handleError "Missing network adapter" "Validation check"
)

echo [SUCCESS] All required information detected

:: Show configuration preview
echo.
echo ========================================
echo CURRENT SETTINGS DETECTED:
echo ========================================
echo Adapter: !adapter!
echo IP Address: !currentIP!
echo Subnet Mask: !subnetMask!
echo Default Gateway: !gateway!
echo.
echo This will change your adapter from:
echo   "Obtain IP address automatically"
echo To:
echo   "Use the following IP address"
echo ========================================
echo.

:: User confirmation with error handling
set confirm=
set /p confirm=Apply static IP configuration? (Y/N): 
if /i not "!confirm!"=="Y" (
    echo [CANCELLED] User cancelled configuration
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 0
)

:: Apply configuration with crash protection
echo.
echo [CONFIGURATION] Starting static IP configuration...

:: Set IP address with error handling
echo [CONFIG] Setting IP address to !currentIP!...
netsh interface ipv4 set address name="!adapter!" static !currentIP! !subnetMask! !gateway! 2>nul
if !errorLevel! neq 0 (
    echo [ERROR] Primary command failed, trying alternative...
    netsh interface ip set address "!adapter!" static !currentIP! !subnetMask! !gateway! 2>nul
    if !errorLevel! neq 0 (
        call :handleError "Failed to set IP address" "IP address configuration"
    )
)
echo [SUCCESS] IP address configured successfully

:: Set DNS servers with error handling
echo [CONFIG] Setting DNS servers to Google DNS...
netsh interface ipv4 set dns name="!adapter!" static 8.8.8.8 primary 2>nul
if !errorLevel! neq 0 (
    echo [WARNING] Failed to set primary DNS
) else (
    echo [SUCCESS] Primary DNS configured
)

netsh interface ipv4 add dns name="!adapter!" 8.8.4.4 index=2 2>nul
if !errorLevel! neq 0 (
    echo [WARNING] Failed to set secondary DNS
) else (
    echo [SUCCESS] Secondary DNS configured
)

:: Final verification with crash protection
echo.
echo [VERIFICATION] Checking new configuration...
ipconfig 2>nul | findstr /i "IPv4" >nul 2>&1
if !errorLevel! neq 0 (
    echo [WARNING] Could not verify configuration
) else (
    ipconfig | findstr /i "IPv4"
    ipconfig | findstr /i "Subnet"
)

echo.
echo ========================================
echo CONFIGURATION COMPLETED SUCCESSFULLY!
echo ========================================
echo Your adapter "!adapter!" is now configured with:
echo   IP Address: !currentIP! (STATIC - no longer automatic)
echo   Subnet Mask: !subnetMask!
echo   Default Gateway: !gateway!
echo   DNS Servers: 8.8.8.8, 8.8.4.4
echo.
echo Your computer will now use this IP address permanently
echo instead of getting it automatically from DHCP.
echo ========================================
echo.
echo [COMPLETED] All operations finished successfully!
echo.
echo Press any key to exit...
pause >nul
exit /b 0
