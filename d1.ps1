# Function to check if kavgui.exe is running
function Is-KavguiRunning {
    return (Get-Process -Name kavgui -ErrorAction SilentlyContinue) -ne $null
}

# Function to add exclusion in Windows Defender
function Add-WindowsDefenderExclusion {
    param (
        [string]$path
    )

    Add-MpPreference -ExclusionPath $path
}

# Function to enable DNS over HTTPS in browsers
function Configure-DNSProtection {
    $dnsServerUrl = "https://dns.dnswarden.com/00s8000000000000001000ivo"

    function Set-Protection-ChromeEdge {
        param (
            [string]$browser
        )

        $registryPath = "HKLM:\Software\Policies\Microsoft\$browser"
        if (!(Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
        }

        Set-ItemProperty -Path $registryPath -Name "DnsOverHttpsMode" -Value "automatic" -Type String
        Set-ItemProperty -Path $registryPath -Name "DnsOverHttpsTemplates" -Value $dnsServerUrl -Type String

        Write-Output "$browser configured to use comprehensive protection settings."
    }

    Set-Protection-ChromeEdge -browser "Chrome"
    Set-Protection-ChromeEdge -browser "Edge"

    function Set-Protection-Firefox {
        $firefoxProfilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles\"
        if (Test-Path $firefoxProfilesPath) {
            $profiles = Get-ChildItem $firefoxProfilesPath -Directory
            foreach ($profile in $profiles) {
                $prefsFile = "$firefoxProfilesPath\$profile\prefs.js"
                if (Test-Path $prefsFile) {
                    Add-Content -Path $prefsFile -Value 'user_pref("network.trr.mode", 2);'
                    Add-Content -Path $prefsFile -Value "user_pref('network.trr.uri', '$dnsServerUrl');"
                    Write-Output "Firefox profile $profile configured to use comprehensive protection settings."
                }
            }
        } else {
            Write-Output "Firefox profiles not found."
        }
    }

    Set-Protection-Firefox
}

# Function to configure RDP brute force protection
function Configure-RDPProtection {
    $maxFailedLogins = 3
    $lockoutDurationMinutes = 10
    $lockoutDurationSeconds = $lockoutDurationMinutes * 60

    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "MaxFailedLogons" -Value $maxFailedLogins -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RemoteAccess\Parameters\AccountLockout" -Name "MaxDenials" -Value $maxFailedLogins -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RemoteAccess\Parameters\AccountLockout" -Name "ResetTime" -Value $lockoutDurationSeconds -Force

    Write-Output "RDP brute force protection configured: max failed logins = $maxFailedLogins, lockout duration = $lockoutDurationMinutes minutes."
}

# Function to download a file with progress
function Download-FileWithProgress {
    param (
        [string]$url,
        [string]$outputPath
    )

    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadProgressChanged += {
        param ($sender, $e)
        Write-Progress -Activity "Downloading" -Status "$($e.ProgressPercentage)% Complete:" -PercentComplete $e.ProgressPercentage
    }
    $webClient.DownloadFile($url, $outputPath)
}

# Main logic
if (Is-KavguiRunning) {
    Write-Output "kavgui.exe is running."

    # Ask user to select option
    $choice = Read-Host "Press 1 to exit or 2 for more protection"

    if ($choice -eq '1') {
        Write-Output "Exiting as per user request."
    }
    elseif ($choice -eq '2') {
        # Ask user if they want to enable protections
        $enableProtection = Read-Host "Do you want to enable protections (ads, tracker, browser, malware, phishing, spying)? (y/n)"
        if ($enableProtection -eq 'y') {
            Configure-DNSProtection
        }

        # Ask user if they want to apply RDP brute force protection
        $enableRDPProtection = Read-Host "Do you want to apply RDP brute force protection? (y/n)"
        if ($enableRDPProtection -eq 'y') {
            Configure-RDPProtection
        }
    }
    else {
        Write-Output "Invalid choice. Exiting."
    }
} else {
    Write-Output "kavgui.exe is not running."
    
    $installAntivirus = Read-Host "Do you want to install the antivirus? (y/n)"
    if ($installAntivirus -eq 'y') {
        $variant = Read-Host "Which antivirus variant do you want to install? (A+/Z+)"
        if ($variant -eq 'A+') {
            $url = "https://nextviewkavach.com/build/KavachA+.exe"
        } elseif ($variant -eq 'Z+') {
            $url = "https://nextviewkavach.com/build/KavachZ+.exe"
        } else {
            Write-Output "Invalid variant selected. Exiting."
            exit
        }

        $randomFolder = New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\$(New-Guid)"
        $installerPath = "$randomFolder\KavachInstaller.exe"

        Write-Output "Downloading installer to $installerPath"
        Download-FileWithProgress -url $url -outputPath $installerPath

        Write-Output "Running the installer"
        Start-Process -FilePath $installerPath -NoNewWindow

        # Ask user to select option
        $choice = Read-Host "Press 1 to exit or 2 for more protection"

        if ($choice -eq '1') {
            Write-Output "Exiting as per user request."
        }
        elseif ($choice -eq '2') {
            # Ask user if they want to enable protections
            $enableProtection = Read-Host "Do you want to enable protections (ads, tracker, browser, malware, phishing, spying)? (y/n)"
            if ($enableProtection -eq 'y') {
                Configure-DNSProtection
            }

            # Ask user if they want to apply RDP brute force protection
            $enableRDPProtection = Read-Host "Do you want to apply RDP brute force protection? (y/n)"
            if ($enableRDPProtection -eq 'y') {
                Configure-RDPProtection
            }
        }
        else {
            Write-Output "Invalid choice. Exiting."
        }
    } else {
        Write-Output "Antivirus installation skipped."
    }
}

# Always add Windows Defender exclusion for C:\Program Files (x86)
Add-WindowsDefenderExclusion -path "C:\Program Files (x86)"

Read-Host "Press any key to exit"
