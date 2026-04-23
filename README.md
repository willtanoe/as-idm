# IDM Management Tool (Professional Edition)

A high-precision PowerShell utility for Internet Download Manager (IDM) registry management, designed for network security researchers.

## Core Features
- **Security-First**: Uses native PowerShell ACL providers instead of risky memory injections.
- **Non-Persistent**: Optimized for memory execution (`iex`) to minimize disk footprint.
- **Enterprise Ready**: Full error handling and support for x64/ARM64 architectures.

## One-Liner Execution
Execute the tool directly in an **Administrative PowerShell** session:

```powershell
irm [https://raw.githubusercontent.com/willtanoe/as-idm/main/idm_tool.ps1](https://raw.githubusercontent.com/willtanoe/as-idm/main/idm_tool.ps1) | iex
```

Methodology
1. Freeze Trial (Recommended)
This method identifies IDM's trial-tracking CLSIDs and applies a Deny Access Control Entry (ACE) for the Everyone identity. This effectively prevents IDM from writing the expiration date, locking the trial in a perpetual "Day 1" state.

2. Reset Mode
Completely purges identified IDM artifacts from the Windows Registry, useful for troubleshooting or re-installations.

3. Activation Mode
Applies a custom license name and serial number. Note that modern IDM versions may detect this via server-side validation.

Disclaimer: This tool is for educational purposes only. Maintainer is not responsible for any legal misuse.
