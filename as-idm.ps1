# IDM Registry Management Tool (Reworked)
# Researcher: Will (S2 Network Engineering & Cyber Security)
# Technical Focus: Native ACL Manipulation & Memory-Only Execution

# Ensure Admin Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Elevation required. Relaunching as Administrator..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Get-IDMRegistryPath {
    $arch = (Get-CimInstance Win32_Processor).AddressWidth
    return if ($arch -eq 64) { "Software\Classes\WOW6432Node\CLSID" } else { "Software\Classes\CLSID" }
}

function Invoke-IDMAction {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Reset", "Freeze")]
        $Mode
    )

    $targetPath = Get-IDMRegistryPath
    $userSID = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $rootPaths = @(
        "HKCU:\$targetPath",
        "Registry::HKEY_USERS\$userSID\$targetPath"
    )

    Write-Host ">>> Initializing $Mode sequence..." -ForegroundColor Cyan

    foreach ($root in $rootPaths) {
        if (-not (Test-Path $root)) { continue }

        # Targeted Regex: Matches standard GUID format
        $clsids = Get-ChildItem -Path $root | Where-Object {
            $_.PSChildName -match '^\{[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}\}$'
        }

        foreach ($item in $clsids) {
            $val = Get-ItemProperty -Path $item.PSPath -Name "(default)" -ErrorAction SilentlyContinue
            
            # IDM Signature: Numeric values or Base64-like characters in default key
            if ($val.'(default)' -match '^\d+$' -or $val.'(default)' -match '\+|==') {
                try {
                    if ($Mode -eq "Reset") {
                        Remove-Item -Path $item.PSPath -Recurse -Force -ErrorAction Stop
                        Write-Host "[-] Deleted: $($item.PSChildName)" -ForegroundColor Gray
                    } 
                    else {
                        # Freeze Mode: Apply Deny ACL for persistence
                        $acl = Get-Acl $item.PSPath
                        $everyone = New-Object System.Security.Principal.NTAccount("Everyone")
                        $rule = New-Object System.Security.AccessControl.RegistryAccessRule($everyone, "FullControl", "Deny")
                        $acl.SetAccessRule($rule)
                        Set-Acl $item.PSPath $acl
                        Write-Host "[*] Locked: $($item.PSChildName)" -ForegroundColor Green
                    }
                } catch {
                    Write-Host "[!] Access Denied: $($item.PSChildName)" -ForegroundColor Red
                }
            }
        }
    }
}

# Terminal UI
Clear-Host
Write-Host "==========================================" -ForegroundColor Magenta
Write-Host "   IDM RESEARCH TOOL - VERSION 2.0        " -ForegroundColor Magenta
Write-Host "==========================================" -ForegroundColor Magenta
Write-Host "1. Freeze Trial (Lifetime Mode)"
Write-Host "2. Reset Trial Data"
Write-Host "0. Exit"
Write-Host "------------------------------------------"

$choice = Read-Host "Select Option"

switch ($choice) {
    "1" { Invoke-IDMAction -Mode "Freeze" }
    "2" { Invoke-IDMAction -Mode "Reset" }
    "0" { exit }
    default { Write-Warning "Invalid selection." }
}

Write-Host "`nOperation completed. Press any key to exit." -ForegroundColor Cyan
$null = [Console]::ReadKey()