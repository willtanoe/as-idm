<#
    IDM PRO TOOL - Robust Remote Edition (Fixed by Peer)
#>

$ScriptBlock = {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    function Get-IDMRegistryPath {
        # Fix Syntax: Pindahin return ke dalam block atau gunakan variabel
        if ([Environment]::Is64BitOperatingSystem) {
            return "Software\Classes\WOW6432Node\CLSID"
        } else {
            return "Software\Classes\CLSID"
        }
    }

    function Invoke-IDMAction {
        param ([string]$Action)
        $REG_PATH = Get-IDMRegistryPath
        $USER_SID = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
        $Targets = @("HKCU:\$REG_PATH", "Registry::HKEY_USERS\$USER_SID\$REG_PATH")

        Write-Host "`n[*] Running $Action sequence..." -ForegroundColor Cyan
        foreach ($Root in $Targets) {
            if (-not (Test-Path $Root)) { continue }
            
            # Filter CLSID IDM dengan Regex
            $Keys = Get-ChildItem $Root -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\{[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}\}$' }
            
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
                    } catch { 
                        Write-Host "[!] Skip: $($Key.PSChildName) (In Use)" -ForegroundColor Red
                    }
                }
            }
        }

        if ($Action -eq "Activate") {
            $Path = "HKCU:\Software\DownloadManager"
            if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
            Set-ItemProperty -Path $Path -Name "FName" -Value "Will_Researcher"
            Set-ItemProperty -Path $Path -Name "LName" -Value "S2_Telkom"
            Set-ItemProperty -Path $Path -Name "Serial" -Value "7G7QY-P5W2G-SJA8R-TK3S6"
            Write-Host "[+] Fake Registration Applied." -ForegroundColor Yellow
        }
    }

    Clear-Host
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host "    ACT Script - IDM (Fixed)" -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host "1. Freeze Trial (Lifetime Mode)"
    Write-Host "2. Reset Trial Data"
    Write-Host "3. Activate (Fake Serial)"
    Write-Host "0. Exit"
    
    # Ganti nama variabel $Input karena itu reserved variable di PowerShell
    $UserChoice = Read-Host "`nSelect Option"
    switch ($UserChoice) {
        "1" { Invoke-IDMAction -Action "Freeze" }
        "2" { Invoke-IDMAction -Action "Reset" }
        "3" { Invoke-IDMAction -Action "Activate" }
        "0" { return }
    }
    Write-Host "`n[+] Operation Finished." -ForegroundColor Cyan
    Write-Host "Press any key to exit..."
    $null = [Console]::ReadKey()
}

# Elevation Logic
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Gunakan cara yang lebih aman buat passing ScriptBlock ke process baru
    Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $ScriptBlock -Verb RunAs
    exit
} else {
    & $ScriptBlock
}
