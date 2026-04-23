# ACT-Script IDM

A PowerShell utility for Internet Download Manager (IDM) registry management/

## Core Features
- **Security-First**: Uses native PowerShell ACL providers instead of risky memory injections.
- **Non-Persistent**: Optimized for memory execution (`iex`) to minimize disk footprint.
- **Enterprise Ready**: Full error handling and support for x64/ARM64 architectures.

## Execution
Execute the tool directly in Windows Terminal / Powershell:

```powershell
irm https://raw.githubusercontent.com/willtanoe/as-idm/main/as-idm.ps1 | iex
```

Methodology
1. Freeze Trial (Recommended)
This method identifies IDM's trial-tracking CLSIDs and applies a Deny Access Control Entry (ACE) for the Everyone identity. This effectively prevents IDM from writing the expiration date, locking the trial in a perpetual "Day 1" state.

2. Reset Mode
Completely purges identified IDM artifacts from the Windows Registry, useful for troubleshooting or re-installations.

3. Activation Mode
Applies a custom license name and serial number. Note that modern IDM versions may detect this via server-side validation.

Disclaimer: This tool is for educational purposes only. Maintainer is not responsible for any legal misuse.

## Credits & Acknowledgments

This project is a **Full PowerShell Rework** of the original [IDM Activation Script (IAS)](https://github.com/WindowsAddict/IDM-Activation-Script) by **WindowsAddict**. 

While the original implementation relied heavily on Windows Batch (.cmd), this version has been completely rewritten into native PowerShell (.ps1) to ensure better performance, cleaner logic, and modern system compatibility for security research purposes.

### The Researchers Behind the Logic:

| Contributor | Contribution & Reference |
| :--- | :--- |
| **Dukun Cabul** | The original researcher who discovered the [IDM trial reset and activation bypass](https://nsaneforums.com/topic/371047-discussion-internet-download-manager-fixes/page/8/#comment-1632062). |
| **AveYo (BAU)** | Author of the legendary [reg_own](https://pastebin.com/XTPt0JSC) snippet for lean registry ownership manipulation. |
| **abbodi1406** | Massive technical contributions and optimizations to the global [activation research](https://github.com/abbodi1406). |
| **WindowsAddict** | Creator of the original [IAS repository](https://github.com/WindowsAddict/IDM-Activation-Script) and community maintainer. |

---
*Disclaimer: This rework is for educational and security research purposes only.*
