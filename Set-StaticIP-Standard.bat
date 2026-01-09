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
echo [Step 1/4] Using default network adapter...
echo.

:: Set default adapter to Ethernet
set adapter=Ethernet
echo Selected adapter: "%adapter%" (Default)
echo Created by Mr. Zohaib
echo.

:: Verify adapter exists
netsh interface show interface name="%adapter%" >nul 2>&1
if %errorLevel% neq 0 (
    echo WARNING: Ethernet adapter not found!
    echo Available adapters:
    netsh interface show interface
    echo.
    echo Please check your network adapter name and update the script.
    pause
    exit /b 1
)

echo SUCCESS: Ethernet adapter found and ready for configuration.
echo.

:: Step 2: Detect current IP settings
echo [Step 2/3] Detecting current IP configuration...
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
echo [Step 3/3] Configuration to be applied:
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
echo Applying static IP configuration...
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

:: Step 5: Get user information for database storage
echo ========================================
echo USER INFORMATION
echo ========================================
echo Please enter your information for database storage:
echo.

set /p userName=Enter your name: 
echo.
echo Thank you, %userName%!
echo.
echo Your information will be stored with the following data:
echo   Name: %userName%
echo   IP Address: %currentIP%
echo   Adapter: %adapter%
echo   Timestamp: %date% %time%
echo.

:: Save information to Google Sheets (and local backup)
echo Saving information to Google Sheets...
echo.

:: Try to send to Google Sheets first
echo Sending data to Google Sheets...
powershell -Command "$body = '{\"name\":\"%userName%\",\"ip\":\"%currentIP%\",\"adapter\":\"%adapter%\",\"timestamp\":\"%date% %time%\"}'; try { $response = Invoke-WebRequest -Uri 'https://script.google.com/macros/s/AKfycbz8QJNtfqpztZtgJ9LVukZ1Nfsd9xaZ4nqQgGUKaPOh8clLQ9TCCZzvY0dTbHiiqRW6/exec' -Method POST -Body $body -ContentType 'application/json' -TimeoutSec 15 -UseBasicParsing -MaximumRedirection 5; if($response.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }"

if %errorLevel% equ 0 (
    echo [SUCCESS] Data sent to Google Sheets successfully!
) else (
    echo [INFO] Google Sheets not available, saving to local file...
    echo Name: %userName% >> StaticIP_Database.txt
    echo IP Address: %currentIP% >> StaticIP_Database.txt
    echo Adapter: %adapter% >> StaticIP_Database.txt
    echo Timestamp: %date% %time% >> StaticIP_Database.txt
    echo ======================================== >> StaticIP_Database.txt
    echo [SUCCESS] Information saved to StaticIP_Database.txt
)

echo.
echo Created by Mr. Zohaib
echo.
echo Press any key to exit...
pause >nul
exit
