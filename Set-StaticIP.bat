@echo off
:: Set-StaticIP.bat
:: Script to convert dynamic IP configuration to static with Google DNS

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges!
    echo Please right-click Command Prompt and select "Run as Administrator"
    pause
    exit /b 1
)

echo Checking for active network adapter...

:: Find active network adapter
for /f "tokens=4" %%i in ('netsh interface show interface ^| findstr "Connected"') do set adapter=%%i

if "%adapter%"=="" (
    echo No active network adapter found!
    echo Available adapters:
    netsh interface show interface
    echo Please ensure your network cable is connected and try again.
    pause
    exit /b 1
)

echo Found active adapter: %adapter%

:: Get current IP configuration
echo Detecting current IP settings...

:: Get current IP address
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4 Address"') do (
    for /f "tokens=*" %%j in ("%%i") do set currentIP=%%j
)

:: Get current subnet mask
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "Subnet Mask"') do (
    for /f "tokens=*" %%j in ("%%i") do set subnetMask=%%j
)

:: Get current default gateway
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "Default Gateway"') do (
    for /f "tokens=*" %%j in ("%%i") do set gateway=%%j
)

:: Clean up variables (remove spaces)
set currentIP=%currentIP: =%
set subnetMask=%subnetMask: =%
set gateway=%gateway: =%

echo Current settings detected:
echo IP Address: %currentIP%
echo Subnet Mask: %subnetMask%
echo Default Gateway: %gateway%

if "%currentIP%"=="" (
    echo No IPv4 address found on adapter %adapter%
    echo Please ensure you have an active network connection.
    pause
    exit /b 1
)

echo.
echo Setting static IP configuration...

:: Set static IP
netsh interface ipv4 set address "%adapter%" static %currentIP% %subnetMask% %gateway%

if %errorLevel% neq 0 (
    echo ERROR: Failed to set static IP address!
    pause
    exit /b 1
)

echo Setting DNS servers to Google DNS...

:: Set DNS servers
netsh interface ipv4 set dns "%adapter%" static 8.8.8.8 primary
netsh interface ipv4 add dns "%adapter%" 8.8.4.4 index=2

if %errorLevel% neq 0 (
    echo ERROR: Failed to set DNS servers!
    pause
    exit /b 1
)

echo.
echo Configuration completed. Verifying settings...
echo.

:: Verify configuration
echo New static configuration:
ipconfig /all | findstr /i "%adapter%"
ipconfig /all | findstr /i "IPv4 Address"
ipconfig /all | findstr /i "Subnet Mask"
ipconfig /all | findstr /i "Default Gateway"
ipconfig /all | findstr /i "DNS Servers"

echo.
echo ========================================
echo FINAL CONFIGURATION SET:
echo IP Address: %currentIP%
echo Subnet Mask: %subnetMask%
echo Default Gateway: %gateway%
echo Primary DNS: 8.8.8.8
echo Alternate DNS: 8.8.4.4
echo ========================================
echo.
echo Static IP configuration completed successfully!
pause
