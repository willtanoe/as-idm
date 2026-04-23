<#
    IDM PRO TOOL - Remote Exec Version
    Author: Will @ Telkom University
#>

$ScriptBlock = {
    # Function definitions inside the block
    function Get-IDMRegistryPath {
        $arch = (Get-CimInstance Win32_Processor).AddressWidth
        return if ($arch -eq 64) { "Software\Classes\WOW6432Node\CLSID" } else { "Software\Classes\CLSID" }
    }

    function Invoke-IDMCleanup {
        param ([string]$Action)
        $REG_PATH = Get-IDMRegistryPath
        $USER_SID = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        $Targets = @("HKCU:\$REG_PATH", "Registry::HKEY_USERS\$USER_SID\$REG_PATH")

        foreach ($Root in $Targets) {
            if (-not (Test-Path $Root)) { continue }
            $Keys = Get-Childitem $Root | Where-Object { $_.PSChildName -match '^\{[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}\}$' }
            foreach ($Key in $Keys) {
                $DefaultVal = (Get-ItemProperty $Key.PSPath -Name "(default)" -ErrorAction SilentlyContinue)."(default)"
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

    # Internal Menu Logic
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host "    IDM PRO TOOL - REMOTE EDITION" -ForegroundColor Magenta
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
    Write-Host "`nDone. Press any key to exit..."
    $null = [Console]::ReadKey()
}

# Elevation Logic that works with IEX
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Elevating to Administrator..."
    $RemoteCommand = "irm https://raw.githubusercontent.com/willtanoe/as-idm/main/as-idm.ps1 | iex"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command $RemoteCommand" -Verb RunAs
    exit
} else {
    & $ScriptBlock
}
