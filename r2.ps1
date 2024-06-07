# Function to check for Administrator Privileges
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

# If not running as administrator, restart the script as administrator
if (-not (Test-Admin)) {
    Write-Host "Script is not running as Administrator. Restarting as Administrator..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Prompt to remove RDP brute force protection
$removeRDPProtection = Read-Host "Do you want to remove RDP brute force protection? (yes/no)"
if ($removeRDPProtection -eq "yes") {
    try {
        # Remove RDP brute force protection settings
        Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "MaxFailedLogins" -ErrorAction Stop
        Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "MaxConnectionTime" -ErrorAction Stop
        Write-Host "RDP brute force protection settings removed."
    } catch {
        Write-Host "Failed to remove RDP brute force protection settings."
    }
} else {
    Write-Host "RDP brute force protection settings not removed."
}

# Prompt to remove DNS over HTTPS protection
$removeDNSProtection = Read-Host "Do you want to remove DNS over HTTPS protection? (yes/no)"
if ($removeDNSProtection -eq "yes") {
    # Remove DNS over HTTPS protection settings for Chrome and Edge
    function Remove-DNSProtection {
        param (
            [string]$browser
        )

        $registryPath = "HKLM:\Software\Policies\Microsoft\$browser"
        if (Test-Path $registryPath) {
            Remove-Item -Path $registryPath -Recurse -Force
            Write-Host "$browser DNS over HTTPS protection settings removed."
        } else {
            Write-Host "$browser DNS over HTTPS protection settings not found."
        }
    }

    # Remove protection settings for Chrome
    Remove-DNSProtection -browser "Chrome"

    # Remove protection settings for Edge
    Remove-DNSProtection -browser "Edge"

    # Remove protection settings for Firefox
    $firefoxProfilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles\"
    if (Test-Path $firefoxProfilesPath) {
        $profiles = Get-ChildItem $firefoxProfilesPath -Directory
        foreach ($profile in $profiles) {
            $prefsFile = "$firefoxProfilesPath\$profile\prefs.js"
            if (Test-Path $prefsFile) {
                (Get-Content $prefsFile) | Where-Object { $_ -notmatch 'network.trr.mode' -and $_ -notmatch 'network.trr.uri' } | Set-Content $prefsFile
                Write-Host "Firefox profile $profile DNS over HTTPS protection settings removed."
            }
        }
    } else {
        Write-Host "Firefox profiles not found."
    }
} else {
    Write-Host "DNS over HTTPS protection settings not removed."
}

Write-Host "Script execution completed."
