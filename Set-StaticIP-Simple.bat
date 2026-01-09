@echo off
:: Set-StaticIP-Simple.bat
:: Simple script to convert dynamic IP to static with error handling

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges!
    echo Please right-click Command Prompt and select "Run as Administrator"
    pause
    exit /b 1
)

:: Enable error handling
setlocal enabledelayedexpansion

echo ========================================
echo Static IP Configuration Tool
echo ========================================
echo.

:: Step 1: Detect current IP address
echo [Step 1/4] Detecting current IP address...
ipconfig | findstr /i "IPv4 Address" > current_ip.txt

if not exist current_ip.txt (
    echo ERROR: Could not detect IP address!
    echo Please ensure you have an active network connection.
    pause
    exit /b 1
)

:: Extract IP address
for /f "tokens=2 delims=:" %%i in (current_ip.txt) do (
    for /f "tokens=*" %%j in ("%%i") do set currentIP=%%j
)

set currentIP=%currentIP: =%
del current_ip.txt

if "%currentIP%"=="" (
    echo ERROR: No IPv4 address found!
    pause
    exit /b 1
)

echo Current IP Address: %currentIP%

:: Step 2: Detect subnet mask and gateway
echo [Step 2/4] Detecting subnet mask and gateway...

for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "Subnet Mask"') do (
    for /f "tokens=*" %%j in ("%%i") do set subnetMask=%%j
)

for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "Default Gateway"') do (
    for /f "tokens=*" %%j in ("%%i") do set gateway=%%j
)

set subnetMask=%subnetMask: =%
set gateway=%gateway: =%

echo Subnet Mask: %subnetMask%
echo Default Gateway: %gateway%

:: Step 3: Detect network adapter
echo [Step 3/4] Detecting network adapter...

:: Try to find the adapter name
set adapter=
for /f "tokens=4" %%i in ('netsh interface show interface ^| findstr "Connected"') do set adapter=%%i

:: If that fails, try common names
if "%adapter%"=="" (
    for %%i in (Ethernet "Local Area Connection" "Wi-Fi") do (
        netsh interface show interface name="%%i" >nul 2>&1
        if !errorLevel! equ 0 (
            set adapter=%%i
            goto :found_adapter
        )
    )
    :found_adapter
)

:: Last resort
if "%adapter%"=="" set adapter=Ethernet

echo Network Adapter: %adapter%

:: Step 4: Apply static configuration
echo [Step 4/4] Applying static IP configuration...

echo.
echo Setting adapter %adapter% to use static IP:
echo   IP Address: %currentIP%
echo   Subnet Mask: %subnetMask%
echo   Gateway: %gateway%
echo   DNS: 8.8.8.8, 8.8.4.4
echo.

:: Set static IP
netsh interface ipv4 set address name="%adapter%" static %currentIP% %subnetMask% %gateway%
if %errorLevel% neq 0 (
    echo ERROR: Failed to set IP address!
    echo Trying alternative method...
    netsh interface ip set address "%adapter%" static %currentIP% %subnetMask% %gateway%
    if %errorLevel% neq 0 (
        echo ERROR: Could not configure IP address!
        pause
        exit /b 1
    )
)

echo IP address set successfully.

:: Set DNS servers
netsh interface ipv4 set dns name="%adapter%" static 8.8.8.8 primary
if %errorLevel% neq 0 (
    echo ERROR: Failed to set primary DNS!
    netsh interface ip set dns "%adapter%" static 8.8.8.8
    if %errorLevel% neq 0 (
        echo WARNING: Could not set DNS servers!
    )
) else (
    netsh interface ipv4 add dns name="%adapter%" 8.8.4.4 index=2
    echo DNS servers set successfully.
)

:: Verify configuration
echo.
echo ========================================
echo VERIFICATION
echo ========================================
echo Verifying new configuration...
ipconfig /all | findstr /i "%adapter%"
ipconfig /all | findstr /i "IPv4 Address"
ipconfig /all | findstr /i "Subnet Mask"
ipconfig /all | findstr /i "Default Gateway"
ipconfig /all | findstr /i "DNS Servers"

echo.
echo ========================================
echo FINAL CONFIGURATION
echo ========================================
echo Adapter: %adapter%
echo IP Address: %currentIP%
echo Subnet Mask: %subnetMask%
echo Default Gateway: %gateway%
echo Primary DNS: 8.8.8.8
echo Alternate DNS: 8.8.4.4
echo ========================================
echo.
echo Static IP configuration completed successfully!
echo Your adapter has been changed from "Obtain IP address automatically"
echo to "Use the following IP address" with your current settings.
echo.
pause
