# Static IP Configuration Scripts

## Overview
This repository contains scripts that automatically detect your current IPv4 network settings (IP address, subnet mask, and default gateway) and convert them from dynamic (DHCP) to static configuration with Google DNS servers.

## Available Scripts

### PowerShell Script (Set-StaticIP.ps1)
- **Language**: PowerShell
- **Requirements**: Windows PowerShell (run as Administrator)
- **Features**: Advanced error handling, detailed logging

### Batch Script (Set-StaticIP.bat)
- **Language**: Command Prompt (Batch)
- **Requirements**: Windows Command Prompt (run as Administrator)
- **Features**: Traditional CMD approach, compatible with older systems

## Features
- Automatically detects active network adapter
- Captures current IP address, subnet mask, and default gateway
- Converts DHCP configuration to static
- Sets DNS servers to Google DNS (8.8.8.8 primary, 8.8.4.4 secondary)
- Verifies the final configuration
- Administrator privilege checking

## Usage

### Prerequisites
- Administrator privileges
- Active network connection with DHCP-assigned IP

### How to Run

#### PowerShell Script
1. Right-click on PowerShell and select "Run as Administrator"
2. Navigate to the script directory
3. Execute the script:
   ```powershell
   .\Set-StaticIP.ps1
   ```

#### Batch Script
1. Right-click on Command Prompt and select "Run as Administrator"
2. Navigate to the script directory
3. Execute the script:
   ```cmd
   Set-StaticIP.bat
   ```

### What the Scripts Do
1. Find the active network adapter
2. Read current IP configuration
3. Remove existing DHCP settings
4. Apply static IP configuration using detected values
5. Set Google DNS servers (8.8.8.8, 8.8.4.4)
6. Display the final configuration

## Notes
- Both scripts require administrator privileges to modify network settings
- PowerShell script works with Ethernet adapters (wired connections)
- Batch script works with any active network interface
- If you need to revert to DHCP, you can use:
  - **PowerShell**: `Set-NetIPInterface -InterfaceAlias "Ethernet" -Dhcp Enabled`
  - **Command Prompt**: `netsh interface ipv4 set address "Ethernet" dhcp`

## Troubleshooting
- If no active adapter is found, ensure your network cable is connected
- If you get permission errors, make sure to run as Administrator
- The scripts will display error messages and available adapters if any step fails
- Batch script shows detailed IP configuration for verification
