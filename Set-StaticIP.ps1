# Set-StaticIP.ps1
# Script to convert dynamic IP configuration to static with Google DNS

# Check for administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges!" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Get active network adapter (LAN only)
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and ($_.InterfaceType -eq "Ethernet" -or $_.InterfaceType -eq "6")} | Select-Object -First 1

if (-not $adapter) {
    Write-Host "No active LAN adapter found!" -ForegroundColor Red
    Write-Host "Available adapters:" -ForegroundColor Yellow
    Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | ForEach-Object {
        Write-Host "  - $($_.Name) (Type: $($_.InterfaceType), Status: $($_.Status))" -ForegroundColor White
    }
    Write-Host "Please ensure your Ethernet cable is connected and try again." -ForegroundColor Yellow
    exit 1
}

try {
    Write-Host "Found active LAN adapter: $($adapter.Name)" -ForegroundColor Green
    
    # Get current IP configuration
    $ipConfig = Get-NetIPConfiguration -InterfaceAlias $adapter.Name -ErrorAction Stop
    
    if (-not $ipConfig.IPv4Address) {
        Write-Host "No IPv4 address found on adapter $($adapter.Name)" -ForegroundColor Red
        Write-Host "Please ensure you have an active network connection." -ForegroundColor Yellow
        exit 1
    }
    
    # Extract current network settings
    $currentIP = $ipConfig.IPv4Address.IPAddress
    $subnetPrefix = $ipConfig.IPv4Address.PrefixLength
    $gateway = $ipConfig.IPv4DefaultGateway.NextHop
    
    # Convert prefix length to subnet mask
    $subnetMask = [System.Net.IPAddress]::Parse(( [System.Net.IPAddress]::Parse([String]([System.Net.IPAddress]::Parse("255.255.255.255").Address -bor ([System.Net.IPAddress]::Parse("0.0.0.0").Address -shl $subnetPrefix))))).Address)
    
    Write-Host "Current settings detected:" -ForegroundColor Yellow
    Write-Host "IP Address: $currentIP"
    Write-Host "Subnet Mask: $subnetMask"
    Write-Host "Default Gateway: $gateway"
    
    # Remove existing DHCP configuration
    Write-Host "`nRemoving DHCP configuration..." -ForegroundColor Yellow
    try {
        Remove-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -Confirm:$false -ErrorAction Stop
        Remove-NetRoute -InterfaceAlias $adapter.Name -AddressFamily IPv4 -Confirm:$false -ErrorAction Stop
    }
    catch {
        Write-Host "Warning: Could not remove existing IP configuration (may not exist)" -ForegroundColor Yellow
    }
    
    # Set static IP configuration
    Write-Host "Setting static IP configuration..." -ForegroundColor Yellow
    New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress $currentIP -PrefixLength $subnetPrefix -DefaultGateway $gateway -ErrorAction Stop
    
    # Set DNS servers
    Write-Host "Setting DNS servers to Google DNS..." -ForegroundColor Yellow
    Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses "8.8.8.8","8.8.4.4" -ErrorAction Stop
    
    # Verify the configuration
    Write-Host "`nConfiguration completed. Verifying settings..." -ForegroundColor Green
    $verifyConfig = Get-NetIPConfiguration -InterfaceAlias $adapter.Name -ErrorAction Stop
    
    Write-Host "`nNew static configuration:" -ForegroundColor Cyan
    Write-Host "IP Address: $($verifyConfig.IPv4Address.IPAddress)"
    Write-Host "Subnet Mask: $subnetMask"
    Write-Host "Default Gateway: $($verifyConfig.IPv4DefaultGateway.NextHop)"
    Write-Host "DNS Servers: $(($verifyConfig.DNSServer | Select-Object -ExpandProperty Address) -join ', ')"
    
    Write-Host "`nStatic IP configuration completed successfully!" -ForegroundColor Green
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "FINAL CONFIGURATION SET:" -ForegroundColor Yellow
    Write-Host "IP Address: $($verifyConfig.IPv4Address.IPAddress)" -ForegroundColor White
    Write-Host "Subnet Mask: $subnetMask" -ForegroundColor White
    Write-Host "Default Gateway: $($verifyConfig.IPv4DefaultGateway.NextHop)" -ForegroundColor White
    Write-Host "Primary DNS: 8.8.8.8" -ForegroundColor White
    Write-Host "Alternate DNS: 8.8.4.4" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
}
catch {
    Write-Host "`nERROR: Failed to configure static IP!" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check your network connection and try running as Administrator." -ForegroundColor Yellow
    exit 1
}
