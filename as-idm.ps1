<#
    IDM PRO TOOL - Robust Remote Edition
#>

$ScriptBlock = {
    # Force TLS 1.2 for secure connection
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    function Get-IDMRegistryPath {
        $arch = (Get-CimInstance Win32_Processor).AddressWidth
        return if ($arch -eq 64) { "Software\Classes\WOW6432Node\CLSID" } else { "Software\Classes\CLSID" }
    }

    function Invoke-IDMAction {
        param ([string]$Action)
        $REG_PATH = Get-IDMRegistryPath
        $USER_SID = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        $Targets = @("HKCU:\$REG_PATH", "Registry::HKEY_USERS\$USER_SID\$REG_PATH")

        Write-Host "`n[*] Running $Action sequence..." -ForegroundColor Cyan
        foreach ($Root in $Targets) {
            if (-not (Test-Path $Root)) { continue }
            $Keys = Get-Childitem $Root -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\{[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}\}$' }
            foreach ($Key in $Keys) {
                $DefaultVal = (Get-ItemProperty -Path $Key.PSPath -Name "(default)" -ErrorAction SilentlyContinue)."(default)"
                if ($DefaultVal -match '^\d+$' -or $DefaultVal -match '\+|==') {
                    try {
                        if ($Action -eq "Reset") { 
                            Remove-Item $Key.PSPath -Recurse -Force -ErrorAction Stop
                            Write-Host "[-] Deleted: $($Key.PSChildName)" -ForegroundColor Gray 
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
        if ($Action -eq "Activate") {
            Set-ItemProperty -Path "HKCU:\Software\DownloadManager" -Name "FName" -Value "Will_Researcher"
            Set-ItemProperty -Path "HKCU:\Software\DownloadManager" -Name "LName" -Value "S2_Telkom"
            Set-ItemProperty -Path "HKCU:\Software\DownloadManager" -Name "Serial" -Value "7G7QY-P5W2G-SJA8R-TK3S6"
            Write-Host "[+] Fake Registration Applied." -ForegroundColor Yellow
        }
    }

    Clear-Host
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host "    IDM PRO TOOL - ULTIMATE STABLE" -ForegroundColor Magenta
    Write-Host "    Author: Will (Network Engineering)" -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host "1. Freeze Trial (Lifetime Mode)"
    Write-Host "2. Reset Trial Data"
    Write-Host "3. Activate (Fake Serial)"
    Write-Host "0. Exit"
    
    $Input = Read-Host "`nSelect Option"
    switch ($Input) {
        "1" { Invoke-IDMAction -Action "Freeze" }
        "2" { Invoke-IDMAction -Action "Reset" }
        "3" { Invoke-IDMAction -Action "Activate" }
        "0" { exit }
    }
    Write-Host "`n[+] Operation Finished." -ForegroundColor Cyan
    Write-Host "Press any key to exit..."
    $null = [Console]::ReadKey()
}

# Elevation Logic with Base64 to prevent crash
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $Url = "https://raw.githubusercontent.com/willtanoe/as-idm/main/as-idm.ps1"
    $Exec = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex (irm $Url)"
    $Encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Exec))
    Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-EncodedCommand", $Encoded -Verb RunAs
    exit
} else {
    & $ScriptBlock
}
