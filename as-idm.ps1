<#
    IDM PRO TOOL - Ultimate Robust Version
    Author: Will @ Telkom University
#>

$ScriptBlock = {
    # Force TLS 1.2 for secure connection
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    function Get-IDMRegistryPath {
        $arch = (Get-CimInstance Win32_Processor).AddressWidth
        return if ($arch -eq 64) { "Software\Classes\WOW6432Node\CLSID" } else { "Software\Classes\CLSID" }
    }

    function Invoke-IDMCleanup {
        param ([string]$Action)
        $REG_PATH = Get-IDMRegistryPath
        $USER_SID = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        $Targets = @("HKCU:\$REG_PATH", "Registry::HKEY_USERS\$USER_SID\$REG_PATH")

        Write-Host "`n[*] Starting $Action sequence..." -ForegroundColor Cyan
        foreach ($Root in $Targets) {
            if (-not (Test-Path $Root)) { continue }
            $Keys = Get-Childitem $Root -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\{[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}\}$' }
            foreach ($Key in $Keys) {
                $DefaultVal = (Get-ItemProperty -Path $Key.PSPath -Name "(default)" -ErrorAction SilentlyContinue)."(default)"
                if ($DefaultVal -match '^\d+$' -or $DefaultVal -match '\+|==') {
                    try {
                        if ($Action -eq "Reset") { 
                            Remove-Item $Key.PSPath -Recurse -Force -ErrorAction Stop
                            Write-Host "[-] Purged: $($Key.PSChildName)" -ForegroundColor Gray 
                        }
                        elseif ($Action -eq "Freeze") {
                            $Acl = Get-Acl $Key.PSPath
                            $Rule = New-Object System.Security.AccessControl.RegistryAccessRule("Everyone", "FullControl", "Deny")
                            $Acl.SetAccessRule($Rule)
                            Set-Acl $Key.PSPath $Acl
                            Write-Host "[*] Locked: $($Key.PSChildName)" -ForegroundColor Green
                        }
                    } catch { }
                }
            }
        }
    }

    Clear-Host
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host "    IDM PRO TOOL - ULTIMATE STABLE" -ForegroundColor Magenta
    Write-Host "    Maintainer: Will (CyberSec Researcher)" -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host "1. Freeze Trial (Stable)"
    Write-Host "2. Reset Trial Data"
    Write-Host "0. Exit"
    
    $Input = Read-Host "`nSelect Option"
    switch ($Input) {
        "1" { Invoke-IDMCleanup -Action "Freeze" }
        "2" { Invoke-IDMCleanup -Action "Reset" }
        "0" { exit }
    }
    Write-Host "`n[+] Operation Finished." -ForegroundColor Cyan
    Write-Host "Press any key to exit..."
    $null = [Console]::ReadKey()
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # We use a more direct way to call the remote script in the new window
    $Url = "https://raw.githubusercontent.com/willtanoe/as-idm/main/as-idm.ps1"
    
    # This command adds a small delay and forces TLS before running irm
    $Exec = "sleep 1; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex (irm $Url)"
    
    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Exec)
    $EncodedCommand = [Convert]::ToBase64String($Bytes)
    
    Write-Host "[!] Elevation required. Spawning Admin Shell..." -ForegroundColor Yellow
    
    # Launching with -NoExit so if it fails, you can see the error instead of it just closing
    Start-Process
