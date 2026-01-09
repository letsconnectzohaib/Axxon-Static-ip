@echo off
:: Set-StaticIP-Auto.bat
:: Automatically detect current IP and make it static

:: Check for administrator privileges
echo [INIT] Checking administrator privileges...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script requires administrator privileges!
    echo [ERROR] Please right-click Command Prompt and select "Run as Administrator"
    echo [FAILED] Administrator privilege check failed
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
echo [SUCCESS] Administrator privileges confirmed

echo ========================================
echo Auto Static IP Configuration
echo ========================================
echo.

:: Step 1: Get current IP address using ipconfig
echo [STEP 1/4] Detecting current IP address...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4 Address"') do set currentIP=%%a
set currentIP=%currentIP: =%

if "%currentIP%"=="" (
    echo [ERROR] Could not detect IP address!
    echo [FAILED] Step 1 - IP address detection
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
echo [SUCCESS] Current IP detected: %currentIP%

:: Step 2: Get subnet mask
echo [STEP 2/4] Detecting subnet mask...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "Subnet Mask"') do set subnetMask=%%a
set subnetMask=%subnetMask: =%

if "%subnetMask%"=="" (
    echo [ERROR] Could not detect subnet mask!
    echo [FAILED] Step 2 - Subnet mask detection
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
echo [SUCCESS] Subnet mask detected: %subnetMask%

:: Step 3: Get default gateway
echo [STEP 3/4] Detecting default gateway...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "Default Gateway"') do set gateway=%%a
set gateway=%gateway: =%

if "%gateway%"=="" (
    echo [ERROR] Could not detect default gateway!
    echo [FAILED] Step 3 - Default gateway detection
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
echo [SUCCESS] Default gateway detected: %gateway%

:: Step 4: Get network adapter name
echo [STEP 4/4] Detecting network adapter...
for /f "tokens=4" %%a in ('netsh interface show interface ^| findstr "Connected"') do set adapter=%%a

:: If no connected adapter, try enabled adapters
if "%adapter%"=="" (
    echo [INFO] No connected adapter found, trying enabled adapters...
    for /f "tokens=4" %%a in ('netsh interface show interface ^| findstr "Enabled"') do set adapter=%%a
)

:: If still no adapter, use common names
if "%adapter%"=="" (
    echo [INFO] No specific adapter found, using default...
    set adapter=Ethernet
)
echo [SUCCESS] Network adapter detected: %adapter%

:: Check if we have all required information
echo.
echo [VALIDATION] Checking all required information...
if "%currentIP%"=="" (
    echo [ERROR] Missing IP address!
    echo [FAILED] Validation check
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

if "%subnetMask%"=="" (
    echo [ERROR] Missing subnet mask!
    echo [FAILED] Validation check
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

if "%gateway%"=="" (
    echo [ERROR] Missing default gateway!
    echo [FAILED] Validation check
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo [SUCCESS] All required information detected

:: Show what will be configured
echo.
echo ========================================
echo CURRENT SETTINGS DETECTED:
echo ========================================
echo Adapter: %adapter%
echo IP Address: %currentIP%
echo Subnet Mask: %subnetMask%
echo Default Gateway: %gateway%
echo.
echo This will change your adapter from:
echo   "Obtain IP address automatically"
echo To:
echo   "Use the following IP address"
echo ========================================
echo.

set /p confirm=Apply static IP configuration? (Y/N): 
if /i not "%confirm%"=="Y" (
    echo [CANCELLED] User cancelled configuration
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

:: Apply static IP configuration
echo.
echo [CONFIGURATION] Starting static IP configuration...

echo [CONFIG] Setting IP address to %currentIP%...
netsh interface ipv4 set address name="%adapter%" static %currentIP% %subnetMask% %gateway%

if %errorLevel% neq 0 (
    echo [ERROR] Failed to set IP address!
    echo [FAILED] IP address configuration
    echo [DEBUG] Adapter: %adapter%
    echo [DEBUG] IP: %currentIP%
    echo [DEBUG] Subnet: %subnetMask%
    echo [DEBUG] Gateway: %gateway%
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
echo [SUCCESS] IP address configured successfully

echo [CONFIG] Setting DNS servers to Google DNS...
netsh interface ipv4 set dns name="%adapter%" static 8.8.8.8 primary
if %errorLevel% neq 0 (
    echo [WARNING] Failed to set primary DNS
) else (
    echo [SUCCESS] Primary DNS configured
)

netsh interface ipv4 add dns name="%adapter%" 8.8.4.4 index=2
if %errorLevel% neq 0 (
    echo [WARNING] Failed to set secondary DNS
) else (
    echo [SUCCESS] Secondary DNS configured
)

echo.
echo ========================================
echo CONFIGURATION COMPLETED SUCCESSFULLY!
echo ========================================
echo Your adapter "%adapter%" is now configured with:
echo   IP Address: %currentIP% (STATIC - no longer automatic)
echo   Subnet Mask: %subnetMask%
echo   Default Gateway: %gateway%
echo   DNS Servers: 8.8.8.8, 8.8.4.4
echo.
echo Your computer will now use this IP address permanently
echo instead of getting it automatically from DHCP.
echo ========================================
echo.

:: Verify the configuration
echo [VERIFICATION] Checking new configuration...
ipconfig | findstr /i "IPv4"
ipconfig | findstr /i "Subnet"
echo.
echo [COMPLETED] All operations finished successfully!
echo.
echo Press any key to exit...
pause >nul
