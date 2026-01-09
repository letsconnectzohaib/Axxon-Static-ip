# Static IP Configuration Script

## Overview
This PowerShell script automatically detects your current IPv4 network settings (IP address, subnet mask, and default gateway) and converts them from dynamic (DHCP) to static configuration with Google DNS servers.

## Features
- Automatically detects active Ethernet adapter
- Captures current IP address, subnet mask, and default gateway
- Converts DHCP configuration to static
- Sets DNS servers to Google DNS (8.8.8.8 primary, 8.8.4.4 secondary)
- Verifies the final configuration

## Usage

### Prerequisites
- Windows PowerShell (run as Administrator)
- Active network connection with DHCP-assigned IP

### How to Run
1. Right-click on PowerShell and select "Run as Administrator"
2. Navigate to the script directory
3. Execute the script:
   ```powershell
   .\Set-StaticIP.ps1
   ```

### What the Script Does
1. Finds the active Ethernet adapter
2. Reads current IP configuration
3. Removes existing DHCP settings
4. Applies static IP configuration using detected values
5. Sets Google DNS servers (8.8.8.8, 8.8.4.4)
6. Displays the final configuration

## Notes
- Script requires administrator privileges to modify network settings
- Only works with Ethernet adapters (wired connections)
- Creates a static configuration using your current IP address
- If you need to revert to DHCP, you can use:
  ```powershell
  Set-NetIPInterface -InterfaceAlias "Ethernet" -Dhcp Enabled
  ```

## Troubleshooting
- If no active adapter is found, ensure your Ethernet cable is connected
- If you get permission errors, make sure to run PowerShell as Administrator
- The script will display error messages if any step fails
# Axxon-Static-ip
