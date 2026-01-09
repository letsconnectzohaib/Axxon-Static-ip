# Set-StaticIP.ps1
# Script to convert dynamic IP configuration to static with Google DNS

# Get active network adapter
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.MediaType -eq "802.3"} | Select-Object -First 1

if (-not $adapter) {
    Write-Host "No active Ethernet adapter found!" -ForegroundColor Red
    exit 1
}

Write-Host "Found active adapter: $($adapter.Name)" -ForegroundColor Green

# Get current IP configuration
$ipConfig = Get-NetIPConfiguration -InterfaceAlias $adapter.Name

if (-not $ipConfig.IPv4Address) {
    Write-Host "No IPv4 address found on adapter $($adapter.Name)" -ForegroundColor Red
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
Remove-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -Confirm:$false
Remove-NetRoute -InterfaceAlias $adapter.Name -AddressFamily IPv4 -Confirm:$false

# Set static IP configuration
Write-Host "Setting static IP configuration..." -ForegroundColor Yellow
New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress $currentIP -PrefixLength $subnetPrefix -DefaultGateway $gateway -ErrorAction Stop

# Set DNS servers
Write-Host "Setting DNS servers to Google DNS..." -ForegroundColor Yellow
Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses "8.8.8.8","8.8.4.4"

# Verify the configuration
Write-Host "`nConfiguration completed. Verifying settings..." -ForegroundColor Green
$verifyConfig = Get-NetIPConfiguration -InterfaceAlias $adapter.Name

Write-Host "`nNew static configuration:" -ForegroundColor Cyan
Write-Host "IP Address: $($verifyConfig.IPv4Address.IPAddress)"
Write-Host "Subnet Mask: $subnetMask"
Write-Host "Default Gateway: $($verifyConfig.IPv4DefaultGateway.NextHop)"
Write-Host "DNS Servers: $(($verifyConfig.DNSServer | Select-Object -ExpandProperty Address) -join ', ')"

Write-Host "`nStatic IP configuration completed successfully!" -ForegroundColor Green
