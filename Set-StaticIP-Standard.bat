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
echo [Step 1/3] Identifying network adapter...
echo.

:: Try common adapter names in order of preference
echo Checking for common network adapters...
echo.

:: Check for Ethernet (most common)
set adapter=Ethernet
echo Checking: "%adapter%"
netsh interface show interface name="%adapter%" >nul 2>&1
if %errorLevel% equ 0 (
    echo SUCCESS: Found "%adapter%"
    goto :adapter_found
)

:: Check for Ethernet 2 (second Ethernet adapter)
set adapter=Ethernet 2
echo Checking: "%adapter%"
netsh interface show interface name="%adapter%" >nul 2>&1
if %errorLevel% equ 0 (
    echo SUCCESS: Found "%adapter%"
    goto :adapter_found
)

:: Check for Wi-Fi adapters
set adapter=Wi-Fi
echo Checking: "%adapter%"
netsh interface show interface name="%adapter%" >nul 2>&1
if %errorLevel% equ 0 (
    echo SUCCESS: Found "%adapter%"
    goto :adapter_found
)

:: Check for Local Area Connection
set adapter=Local Area Connection
echo Checking: "%adapter%"
netsh interface show interface name="%adapter%" >nul 2>&1
if %errorLevel% equ 0 (
    echo SUCCESS: Found "%adapter%"
    goto :adapter_found
)

:: Check for Local Area Connection 2
set adapter=Local Area Connection 2
echo Checking: "%adapter%"
netsh interface show interface name="%adapter%" >nul 2>&1
if %errorLevel% equ 0 (
    echo SUCCESS: Found "%adapter%"
    goto :adapter_found
)

:: No common adapters found, show all available adapters
echo WARNING: No common network adapters found!
echo.
echo All available network adapters:
echo ========================================
netsh interface show interface | findstr /v "-----" | findstr /v "Admin State" | findstr /v "Type" | findstr /v "^$" | findstr "Connected"
echo ========================================
echo.

:: Let user choose from connected adapters only
echo Please select a CONNECTED adapter from the list above.
set /p adapter=Enter adapter name exactly as shown (including spaces): 
echo.

:: Verify user's choice
if "%adapter%"=="" (
    echo ERROR: No adapter name entered.
    echo Please run the script again and enter a valid adapter name.
    pause
    exit /b 1
)

:: Use quotes for adapter names with spaces
netsh interface show interface name="%adapter%" >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Adapter "%adapter%" not found or not connected!
    echo.
    echo Troubleshooting steps:
    echo 1. Ensure adapter name is spelled exactly as shown (including spaces)
    echo 2. Make sure the adapter is connected (check cable or Wi-Fi)
    echo 3. Try running this script as Administrator
    echo 4. Check Device Manager for disabled adapters
    echo 5. Ensure network adapter is enabled in Control Panel
    echo.
    echo Available CONNECTED adapters again:
    netsh interface show interface | findstr /v "-----" | findstr /v "Admin State" | findstr /v "Type" | findstr /v "^$" | findstr "Connected"
    echo.
    pause
    exit /b 1
)

:adapter_found
echo SUCCESS: Adapter "%adapter%" verified and ready for configuration.
echo.

:: Step 2: Detect current IP settings
echo [Step 2/3] Detecting current IP configuration...
echo.

:: Method 1: Try netsh interface ipv4 show config (Microsoft preferred method)
echo Attempting to detect IP using netsh...
for /f "tokens=*" %%i in ('netsh interface ipv4 show config "%adapter%" ^| findstr /i "IP Address:"') do (
    for /f "tokens=3" %%j in ("%%i") do set currentIP=%%j
)

for /f "tokens=*" %%i in ('netsh interface ipv4 show config "%adapter%" ^| findstr /i "Subnet Prefix:"') do (
    for /f "tokens=3 delims=( " %%j in ("%%i") do set subnetPrefix=%%j
    :: Convert prefix length to subnet mask
    call :ConvertPrefixToMask !subnetPrefix!
)

for /f "tokens=*" %%i in ('netsh interface ipv4 show config "%adapter%" ^| findstr /i "Default Gateway:"') do (
    for /f "tokens=3" %%j in ("%%i") do set gateway=%%j
)

:: Fallback Method 2: Use ipconfig if netsh fails
if "%currentIP%"=="" (
    echo netsh method failed, trying ipconfig...
    for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4 Address"') do (
        for /f "tokens=*" %%j in ("%%i") do set currentIP=%%j
    )
    set currentIP=%currentIP: =%

    for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "Subnet Mask"') do (
        for /f "tokens=*" %%j in ("%%i") do set subnetMask=%%j
    )
    set subnetMask=%subnetMask: =%

    for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "Default Gateway"') do (
        for /f "tokens=*" %%j in ("%%i") do set gateway=%%j
    )
    set gateway=%gateway: =%
)

:: Fallback Method 3: Try WMIC if both netsh and ipconfig fail
if "%currentIP%"=="" (
    echo ipconfig method failed, trying WMIC...
    for /f "tokens=2 delims=," %%i in ('wmic nicconfig where "IPEnabled=TRUE" get IPAddress /format:csv ^| findstr /v "^$"') do (
        for /f "tokens=1 delims=;" %%j in ("%%i") do set currentIP=%%j
    )

    for /f "tokens=2 delims=," %%i in ('wmic nicconfig where "IPEnabled=TRUE" get IPSubnet /format:csv ^| findstr /v "^$"') do (
        set subnetMask=%%i
    )

    for /f "tokens=2 delims=," %%i in ('wmic nicconfig where "IPEnabled=TRUE" get DefaultIPGateway /format:csv ^| findstr /v "^$"') do (
        set gateway=%%i
    )
)

:: Clean up any remaining spaces
set currentIP=%currentIP: =%
set subnetMask=%subnetMask: =%
set gateway=%gateway: =%

:: Validate detected values
if "%currentIP%"=="" (
    echo ERROR: Could not detect IP address!
    echo Please check network connection and adapter status.
    pause
    exit /b 1
)

if "%subnetMask%"=="" (
    echo WARNING: Could not detect subnet mask, using default...
    set subnetMask=255.255.255.0
)

if "%gateway%"=="" (
    echo WARNING: Could not detect default gateway, using common default...
    set gateway=192.168.1.1
)

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

:: Team selection
echo Select your team:
echo 1: Team Haseeb
echo 2: Team Fahad
echo 3: Team Abdullah
echo 4: Team Raja Nafeel
echo 5: Team Hashim Khan
echo 6: Team Abdul Manan
echo 7: Others
echo.

set /p teamChoice=Enter team number (1-7): 
if "%teamChoice%"=="1" set teamName=Team Haseeb
if "%teamChoice%"=="2" set teamName=Team Fahad
if "%teamChoice%"=="3" set teamName=Team Abdullah
if "%teamChoice%"=="4" set teamName=Team Raja Nafeel
if "%teamChoice%"=="5" set teamName=Team Hashim Khan
if "%teamChoice%"=="6" set teamName=Team Abdul Manan
if "%teamChoice%"=="7" set teamName=Others
if "%teamChoice%"=="" set teamName=Team Haseeb

if "%teamName%"=="" (
    echo Invalid team selection. Defaulting to Team Haseeb.
    set teamName=Team Haseeb
)

echo.
set /p agentName=Enter your name: 
echo.
echo Thank you, %agentName%!
echo.
echo Your information will be stored with the following data:
echo   Team: %teamName%
echo   Agent Name: %agentName%
echo   IP Address: %currentIP%
echo   Adapter: %adapter%
echo   Timestamp: %date% %time%
echo.

:: Save information to Google Sheets (and local backup)
echo Saving information to Google Sheets...
echo.

:: Try to send to Google Sheets first
echo Sending data to Google Sheets...
powershell -Command "$body = '{\"teamName\":\"%teamName%\",\"agentName\":\"%agentName%\",\"ip\":\"%currentIP%\",\"adapter\":\"%adapter%\",\"timestamp\":\"%date% %time%\"}'; try { $response = Invoke-WebRequest -Uri 'https://script.google.com/macros/s/AKfycbwnQY04lRwKOSB44SziNp81KYCW_H5dLhuj9qlixwRbjb9-X5D5VjsKYFiJVLZ4IlLT/exec' -Method POST -Body $body -ContentType 'application/json' -TimeoutSec 15 -UseBasicParsing -MaximumRedirection 5; if($response.StatusCode -eq 200) { exit 0 } else { exit 1 } } catch { exit 1 }"

if %errorLevel% equ 0 (
    echo [SUCCESS] Data sent to Google Sheets successfully!
) else (
    echo [INFO] Google Sheets not available, saving to local file...
    echo Team: %teamName% >> StaticIP_Database.txt
    echo Agent Name: %agentName% >> StaticIP_Database.txt
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

:: ========================================
:: SUBROUTINES
:: ========================================

:ConvertPrefixToMask
set prefix=%1
if "%prefix%"=="8" set subnetMask=255.0.0.0
if "%prefix%"=="9" set subnetMask=255.128.0.0
if "%prefix%"=="10" set subnetMask=255.192.0.0
if "%prefix%"=="11" set subnetMask=255.224.0.0
if "%prefix%"=="12" set subnetMask=255.240.0.0
if "%prefix%"=="13" set subnetMask=255.248.0.0
if "%prefix%"=="14" set subnetMask=255.252.0.0
if "%prefix%"=="15" set subnetMask=255.254.0.0
if "%prefix%"=="16" set subnetMask=255.255.0.0
if "%prefix%"=="17" set subnetMask=255.255.128.0
if "%prefix%"=="18" set subnetMask=255.255.192.0
if "%prefix%"=="19" set subnetMask=255.255.224.0
if "%prefix%"=="20" set subnetMask=255.255.240.0
if "%prefix%"=="21" set subnetMask=255.255.248.0
if "%prefix%"=="22" set subnetMask=255.255.252.0
if "%prefix%"=="23" set subnetMask=255.255.254.0
if "%prefix%"=="24" set subnetMask=255.255.255.0
if "%prefix%"=="25" set subnetMask=255.255.255.128
if "%prefix%"=="26" set subnetMask=255.255.255.192
if "%prefix%"=="27" set subnetMask=255.255.255.224
if "%prefix%"=="28" set subnetMask=255.255.255.240
if "%prefix%"=="29" set subnetMask=255.255.255.248
if "%prefix%"=="30" set subnetMask=255.255.255.252
if "%prefix%"=="31" set subnetMask=255.255.255.254
if "%prefix%"=="32" set subnetMask=255.255.255.255
if "%subnetMask%"=="" set subnetMask=255.255.255.0
goto :eof
