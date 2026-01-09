@echo off
:: Set-StaticIP-Auto.bat
:: Automatically detect current IP and make it static

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges!
    echo Please right-click Command Prompt and select "Run as Administrator"
    pause
    exit /b 1
)

echo ========================================
echo Auto Static IP Configuration
echo ========================================
echo.

:: Step 1: Get current IP address using ipconfig
echo [1/4] Detecting current IP address...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4 Address"') do set currentIP=%%a
set currentIP=%currentIP: =%
echo Current IP: %currentIP%

:: Step 2: Get subnet mask
echo [2/4] Detecting subnet mask...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "Subnet Mask"') do set subnetMask=%%a
set subnetMask=%subnetMask: =%
echo Subnet Mask: %subnetMask%

:: Step 3: Get default gateway
echo [3/4] Detecting default gateway...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "Default Gateway"') do set gateway=%%a
set gateway=%gateway: =%
echo Default Gateway: %gateway%

:: Step 4: Get network adapter name
echo [4/4] Detecting network adapter...
for /f "tokens=4" %%a in ('netsh interface show interface ^| findstr "Connected"') do set adapter=%%a

:: If no connected adapter, try enabled adapters
if "%adapter%"=="" (
    for /f "tokens=4" %%a in ('netsh interface show interface ^| findstr "Enabled"') do set adapter=%%a
)

:: If still no adapter, use common names
if "%adapter%"=="" (
    set adapter=Ethernet
)
echo Network Adapter: %adapter%

:: Check if we have all required information
if "%currentIP%"=="" (
    echo ERROR: Could not detect IP address!
    pause
    exit /b 1
)

if "%subnetMask%"=="" (
    echo ERROR: Could not detect subnet mask!
    pause
    exit /b 1
)

if "%gateway%"=="" (
    echo ERROR: Could not detect default gateway!
    pause
    exit /b 1
)

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
    echo Configuration cancelled.
    pause
    exit /b 1
)

:: Apply static IP configuration
echo.
echo Applying static IP configuration...

echo Setting IP address to %currentIP%...
netsh interface ipv4 set address name="%adapter%" static %currentIP% %subnetMask% %gateway%

if %errorLevel% neq 0 (
    echo ERROR: Failed to set IP address!
    pause
    exit /b 1
)

echo Setting DNS servers to Google DNS...
netsh interface ipv4 set dns name="%adapter%" static 8.8.8.8 primary
netsh interface ipv4 add dns name="%adapter%" 8.8.4.4 index=2

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
echo Verifying new configuration:
ipconfig | findstr /i "IPv4"
ipconfig | findstr /i "Subnet"
echo.
pause
