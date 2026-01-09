@echo off
:: Set-StaticIP-Fixed.bat
:: Fixed script to convert dynamic IP to static

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges!
    echo Please right-click Command Prompt and select "Run as Administrator"
    pause
    exit /b 1
)

echo ========================================
echo Static IP Configuration Tool
echo ========================================
echo.

:: Step 1: Show current configuration
echo [Step 1] Current IP Configuration:
ipconfig | findstr "IPv4"
ipconfig | findstr "Subnet"
ipconfig | findstr "Gateway"
echo.

:: Step 2: Get user input for current settings
echo [Step 2] Please enter your current network settings:
set /p currentIP=Enter your current IP address (e.g., 192.168.1.100): 
set /p subnetMask=Enter your subnet mask (e.g., 255.255.255.0): 
set /p gateway=Enter your default gateway (e.g., 192.168.1.1): 
echo.

:: Step 3: Show available adapters
echo [Step 3] Available Network Adapters:
netsh interface show interface
echo.

:: Step 4: Get adapter name from user
set /p adapter=Enter the exact adapter name from above list: 
echo.

:: Step 5: Confirm settings
echo [Step 4] Configuration to be applied:
echo Adapter: %adapter%
echo IP Address: %currentIP%
echo Subnet Mask: %subnetMask%
echo Default Gateway: %gateway%
echo Primary DNS: 8.8.8.8
echo Alternate DNS: 8.8.4.4
echo.

set /p confirm=Apply these settings? (Y/N): 
if /i not "%confirm%"=="Y" (
    echo Configuration cancelled.
    pause
    exit /b 1
)

:: Step 6: Apply static configuration
echo [Step 5] Applying static IP configuration...

echo Setting IP address...
netsh interface ipv4 set address name="%adapter%" static %currentIP% %subnetMask% %gateway%
if %errorLevel% neq 0 (
    echo ERROR: Failed to set IP address!
    echo Trying alternative command...
    netsh interface ip set address "%adapter%" static %currentIP% %subnetMask% %gateway%
    if %errorLevel% neq 0 (
        echo ERROR: Could not configure IP address!
        echo Check adapter name and try again.
        pause
        exit /b 1
    )
)

echo Setting DNS servers...
netsh interface ipv4 set dns name="%adapter%" static 8.8.8.8 primary
netsh interface ipv4 add dns name="%adapter%" 8.8.4.4 index=2

echo.
echo ========================================
echo CONFIGURATION COMPLETED
echo ========================================
echo Adapter %adapter% has been configured with static IP:
echo   IP Address: %currentIP%
echo   Subnet Mask: %subnetMask%
echo   Default Gateway: %gateway%
echo   DNS Servers: 8.8.8.8, 8.8.4.4
echo.
echo Your adapter is now set to "Use the following IP address"
echo instead of "Obtain IP address automatically".
echo ========================================
echo.
pause
