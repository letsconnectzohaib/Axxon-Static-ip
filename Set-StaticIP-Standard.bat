@echo off
:: Set-StaticIP-Standard.bat
:: Standard method following Microsoft best practices
:: Created by Mr. Zohaib

:: Enable delayed expansion for better variable handling
setlocal enabledelayedexpansion

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges!
    echo Please right-click Command Prompt and select "Run as Administrator"
    pause
    exit /b 1
)

echo ========================================
echo Standard Static IP Configuration
echo Following Microsoft Best Practices
echo Created by Mr. Zohaib
echo ========================================
echo.

:: Step 1: Identify Network Adapter Name
echo [Step 1/4] Identifying your network adapter...
echo.
echo Available network interfaces:
netsh interface show interface
echo.

:: Create menu for adapter selection
echo Please select your network adapter:
echo.
set /a adapterCount=0
set adapterList=

:: Build adapter list with numbers
for /f "tokens=4" %%i in ('netsh interface show interface ^| findstr "Connected"') do (
    set /a adapterCount+=1
    set adapter!adapterCount!=%%i
    echo [!adapterCount!] %%i
)

:: If no connected adapters, show enabled ones
if %adapterCount% equ 0 (
    echo No connected adapters found. Showing enabled adapters:
    for /f "tokens=4" %%i in ('netsh interface show interface ^| findstr "Enabled"') do (
        set /a adapterCount+=1
        set adapter!adapterCount!=%%i
        echo [!adapterCount!] %%i
    )
)

if %adapterCount% equ 0 (
    echo ERROR: No network adapters found!
    pause
    exit /b 1
)

echo.
set /p choice=Enter the number of your adapter [1-%adapterCount%]: 

:: Validate choice
if %choice% leq 0 (
    echo ERROR: Invalid selection!
    pause
    exit /b 1
)

if %choice% gtr %adapterCount% (
    echo ERROR: Invalid selection!
    pause
    exit /b 1
)

:: Get selected adapter name
set adapter=!adapter%choice%!
echo.
echo Selected adapter: "%adapter%"
echo Created by Mr. Zohaib
echo.

:: Step 2: Detect current IP settings
echo [Step 2/4] Detecting current IP configuration...
echo.

:: Get current IP address
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4 Address"') do (
    for /f "tokens=*" %%j in ("%%i") do set currentIP=%%j
)
set currentIP=%currentIP: =%

:: Get current subnet mask
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "Subnet Mask"') do (
    for /f "tokens=*" %%j in ("%%i") do set subnetMask=%%j
)
set subnetMask=%subnetMask: =%

:: Get current default gateway
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "Default Gateway"') do (
    for /f "tokens=*" %%j in ("%%i") do set gateway=%%j
)
set gateway=%gateway: =%

echo Current IP Address: %currentIP%
echo Current Subnet Mask: %subnetMask%
echo Current Default Gateway: %gateway%
echo.

:: Step 3: Confirm configuration
echo [Step 3/4] Configuration to be applied:
echo   Interface Name: "%adapter%"
echo   IP Address: %currentIP%
echo   Subnet Mask: %subnetMask%
echo   Default Gateway: %gateway%
echo   Primary DNS: 8.8.8.8
echo   Secondary DNS: 8.8.4.4
echo.

set /p confirm=Apply this static IP configuration? (Y/N): 
if /i not "%confirm%"=="Y" (
    echo Configuration cancelled.
    pause
    exit /b 1
)

:: Step 4: Apply static IP configuration
echo [Step 4/4] Applying static IP configuration...
echo.

echo Setting static IP address...
netsh interface ipv4 set address name="%adapter%" static %currentIP% %subnetMask% %gateway%
if %errorLevel% neq 0 (
    echo ERROR: Failed to set IP address!
    echo Please check the adapter name and try again.
    pause
    exit /b 1
)
echo SUCCESS: IP address configured.

echo Setting primary DNS server...
netsh interface ipv4 set dns name="%adapter%" static 8.8.8.8
if %errorLevel% neq 0 (
    echo WARNING: Failed to set primary DNS server.
) else (
    echo SUCCESS: Primary DNS configured.
)

echo Setting secondary DNS server...
netsh interface ipv4 add dns name="%adapter%" 8.8.4.4 index=2
if %errorLevel% neq 0 (
    echo WARNING: Failed to set secondary DNS server.
) else (
    echo SUCCESS: Secondary DNS configured.
)

echo.
echo ========================================
echo VERIFICATION
echo ========================================
echo Verifying the changes...
echo.

ipconfig /all | findstr /i "DHCP Enabled"
ipconfig /all | findstr /i "IPv4 Address"
ipconfig /all | findstr /i "Subnet Mask"
ipconfig /all | findstr /i "Default Gateway"
ipconfig /all | findstr /i "DNS Servers"

echo.
echo ========================================
echo CONFIGURATION COMPLETED
echo ========================================
echo Your adapter "%adapter%" has been configured with static IP:
echo   IP Address: %currentIP%
echo   Subnet Mask: %subnetMask%
echo   Default Gateway: %gateway%
echo   DNS Servers: 8.8.8.8, 8.8.4.4
echo.
echo Note: DHCP should now show as "No" for this adapter.
echo.
echo To revert back to automatic IP later, use:
echo   netsh interface ipv4 set address name="%adapter%" source=dhcp
echo.
pause
