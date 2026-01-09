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

:: Enable delayed expansion for better variable handling
setlocal enabledelayedexpansion

echo Checking for active network adapter...

:: Approach 1: Try netsh interface show interface
set adapter=
for /f "tokens=*" %%i in ('netsh interface show interface ^| findstr "Connected"') do (
    for /f "tokens=*" %%j in ("%%i") do set adapter=%%j
)

:: Clean up adapter name (remove status and other info)
if not "%adapter%"=="" (
    for /f "tokens=*" %%i in ("%adapter%") do (
        for /f "tokens=1" %%j in ("%%i") do set adapter=%%j
    )
)

:: Approach 2: If approach 1 failed, try wmic
if "%adapter%"=="" (
    echo Approach 1 failed, trying WMIC...
    for /f "tokens=*" %%i in ('wmic path win32_networkadapter where "NetConnectionStatus=2" get NetConnectionID /value ^| findstr "="') do (
        for /f "tokens=2 delims==" %%j in ("%%i") do set adapter=%%j
    )
    set adapter=%adapter: =%
)

:: Approach 3: If approach 2 failed, try ipconfig
if "%adapter%"=="" (
    echo Approach 2 failed, trying ipconfig...
    for /f "tokens=1" %%i in ('ipconfig ^| findstr /i "adapter" ^| findstr /v "media"') do (
        for /f "tokens=1" %%j in ("%%i") do set adapter=%%j
    )
    set adapter=%adapter::=%
)

:: Approach 4: If approach 3 failed, try registry
if "%adapter%"=="" (
    echo Approach 3 failed, trying registry...
    for /f "tokens=3" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkCards" /s /v "ServiceName" ^| findstr "ServiceName"') do (
        for /f %%j in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\%%i" /v "DhcpIPAddress" 2^>nul ^| findstr "DhcpIPAddress"') do (
            set adapter=%%i
        )
    )
)

:: Approach 5: If approach 4 failed, try netstat
if "%adapter%"=="" (
    echo Approach 4 failed, trying netstat...
    for /f "tokens=1" %%i in ('netstat -rn ^| findstr "0.0.0.0"') do (
        set adapter=%%i
    )
    if not "%adapter%"=="" set adapter=Ethernet
)

:: Approach 6: If approach 5 failed, try common adapter names
if "%adapter%"=="" (
    echo Approach 5 failed, trying common adapter names...
    for %%i in (Ethernet "Local Area Connection" "Wi-Fi" "Wireless Network Connection" "Ethernet 2" "Local Area Connection 2") do (
        netsh interface show interface name="%%i" >nul 2>&1
        if !errorLevel! equ 0 (
            set adapter=%%i
            goto :adapter_found
        )
    )
    :adapter_found
)

:: Approach 7: Last resort - use first available interface
if "%adapter%"=="" (
    echo All specific approaches failed, using first available interface...
    for /f "tokens=4" %%i in ('netsh interface show interface ^| findstr "Enabled"') do (
        set adapter=%%i
        goto :final_adapter
    )
    :final_adapter
)

if "%adapter%"=="" (
    echo All approaches failed! No active network adapter found!
    echo Available adapters:
    netsh interface show interface
    echo.
    echo WMIC adapters:
    wmic path win32_networkadapter get NetConnectionID, NetConnectionStatus
    echo Please ensure your network cable is connected and try again.
    pause
    exit /b 1
)

echo Found active adapter: %adapter%

:: Get current IP configuration
echo Detecting current IP settings...

:: Approach 1: Try ipconfig parsing
set currentIP=
set subnetMask=
set gateway=

for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4 Address"') do (
    for /f "tokens=*" %%j in ("%%i") do set currentIP=%%j
)

for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "Subnet Mask"') do (
    for /f "tokens=*" %%j in ("%%i") do set subnetMask=%%j
)

for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "Default Gateway"') do (
    for /f "tokens=*" %%j in ("%%i") do set gateway=%%j
)

:: Approach 2: If ipconfig parsing failed, try wmic
if "%currentIP%"=="" (
    echo ipconfig parsing failed, trying WMIC...
    for /f "tokens=2 delims=," %%i in ('wmic path win32_networkadapterconfiguration where "IPEnabled=True" get IPAddress,IPSubnet,DefaultIPGateway /format:csv ^| findstr ","') do (
        for /f "tokens=1-3 delims=," %%a in ("%%i") do (
            set currentIP=%%a
            set subnetMask=%%b
            set gateway=%%c
        )
    )
    :: Clean up WMIC output (remove quotes and extra characters)
    set currentIP=%currentIP:"=%
    set currentIP=%currentIP:{=%
    set currentIP=%currentIP:}=%
    set subnetMask=%subnetMask:"=%
    set subnetMask=%subnetMask:{=%
    set subnetMask=%subnetMask:}=%
    set gateway=%gateway:"=%
    set gateway=%gateway:{=%
    set gateway=%gateway:}=%
)

:: Approach 3: If still failed, prompt user
if "%currentIP%"=="" (
    echo Automatic detection failed!
    echo Please enter your current IP configuration manually:
    set /p currentIP=Enter IP Address: 
    set /p subnetMask=Enter Subnet Mask (usually 255.255.255.0): 
    set /p gateway=Enter Default Gateway: 
)

:: Approach 4: Try ipconfig /all for more details
if "%currentIP%"=="" (
    echo Trying ipconfig /all for detailed information...
    ipconfig /all > temp_ip.txt
    for /f "tokens=2 delims=:" %%i in ('findstr /i "IPv4 Address" temp_ip.txt') do (
        for /f "tokens=*" %%j in ("%%i") do set currentIP=%%j
    )
    for /f "tokens=2 delims=:" %%i in ('findstr /i "Subnet Mask" temp_ip.txt') do (
        for /f "tokens=*" %%j in ("%%i") do set subnetMask=%%j
    )
    for /f "tokens=2 delims=:" %%i in ('findstr /i "Default Gateway" temp_ip.txt') do (
        for /f "tokens=*" %%j in ("%%i") do set gateway=%%j
    )
    del temp_ip.txt 2>nul
)

:: Approach 5: Try route print for gateway
if "%gateway%"=="" (
    echo Using route print to find gateway...
    for /f "tokens=2,3" %%i in ('route print ^| findstr "0.0.0.0"') do (
        if "%%i"=="0.0.0.0" set gateway=%%j
    )
)

:: Approach 6: Try ping to detect network
if "%currentIP%"=="" (
    echo Trying to detect network via ping...
    ping -n 1 8.8.8.8 >nul 2>&1
    if !errorLevel! equ 0 (
        echo Network detected but IP could not be determined automatically.
        set /p currentIP=Please enter your IP Address: 
        if "%subnetMask%"=="" set subnetMask=255.255.255.0
        if "%gateway%"=="" set /p gateway=Please enter your Gateway: 
    )
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
netsh interface ipv4 set address name="%adapter%" static %currentIP% %subnetMask% %gateway%

if %errorLevel% neq 0 (
    echo ERROR: Failed to set static IP address!
    pause
    exit /b 1
)

echo Setting DNS servers to Google DNS...

:: Set DNS servers
netsh interface ipv4 set dns name="%adapter%" static 8.8.8.8 primary
netsh interface ipv4 add dns name="%adapter%" 8.8.4.4 index=2

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
