# Function to show download progress
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

# Function to enable DNS over HTTPS in browsers
function Configure-DNSProtection {
    $configure = Read-Host "Do you want to configure DNS over HTTPS protection? (yes/no)"
    if ($configure -eq "yes") {
        # Define the DNS over HTTPS server URL
        $dnsServerUrl = "https://dns.dnswarden.com/00s8000000000000001000ivo"

        # Configure protection settings for Chrome and Edge
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

            Write-Host "$browser configured to use comprehensive protection settings."
        }

        # Apply protection settings for Chrome
        Set-Protection-ChromeEdge -browser "Chrome"

        # Apply protection settings for Edge
        Set-Protection-ChromeEdge -browser "Edge"

        # Configure protection settings for Firefox
        function Set-Protection-Firefox {
            $firefoxProfilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles\"
            if (Test-Path $firefoxProfilesPath) {
                $profiles = Get-ChildItem $firefoxProfilesPath -Directory
                foreach ($profile in $profiles) {
                    $prefsFile = "$firefoxProfilesPath\$profile\prefs.js"
                    if (Test-Path $prefsFile) {
                        Add-Content -Path $prefsFile -Value 'user_pref("network.trr.mode", 2);'
                        Add-Content -Path $prefsFile -Value "user_pref('network.trr.uri', '$dnsServerUrl');"
                        Write-Host "Firefox profile $profile configured to use comprehensive protection settings."
                    }
                }
            } else {
                Write-Host "Firefox profiles not found."
            }
        }

        # Apply protection settings for Firefox
        Set-Protection-Firefox
    } else {
        Write-Host "DNS over HTTPS protection not configured."
    }
}

# Function to configure RDP brute force protection via local security policy
function Configure-RDPProtection {
    param (
        [int]$maxFailedLogins = 3,
        [int]$lockoutDurationMinutes = 10
    )

    try {
        # Configure RDP brute force protection
        secedit.exe /export /cfg "$env:temp\rdp.cfg"    # Export current security policy to a file
        (Get-Content "$env:temp\rdp.cfg") | ForEach-Object {
            $_ -replace "ResetLockoutCounters = \d+", "ResetLockoutCounters = $lockoutDurationMinutes" `
               -replace "LockoutBadCount = \d+", "LockoutBadCount = $maxFailedLogins" `
               -replace "LockoutDuration = \d+", "LockoutDuration = $lockoutDurationMinutes"
        } | Set-Content "$env:temp\rdp.cfg"            # Update the exported policy file

        secedit.exe /configure /db "$env:windir\security\Database\rdp.sdb" /cfg "$env:temp\rdp.cfg"  # Configure new security policy

        Write-Output "RDP brute force protection configured:"
        Write-Output "Max failed logins: $maxFailedLogins"
        Write-Output "Lockout duration: $lockoutDurationMinutes minutes"
    }
    catch {
        Write-Error "Failed to configure RDP brute force protection: $_"
    }
}

# Function to check if kavgui.exe is running
function Check-KAVGUIRunning {
    $process = Get-Process -Name kavgui -ErrorAction SilentlyContinue
    return $process -ne $null
}

# Main script logic
if (Check-KAVGUIRunning) {
    Write-Host "kavgui.exe is running."

    # Ask user about enabling various protections
    $enableProtection = Read-Host "Do you want to enable protections (ads, tracker, browser, malware, phishing, spying)? (y/n)"
    if ($enableProtection -eq 'y') {
        Write-Host "Enabling protections..."
        Configure-DNSProtection
        # Add your other protection enabling logic here
    }

    # Ask user if they want to apply RDP brute force protection
    $enableRDPProtection = Read-Host "Do you want to apply RDP brute force protection? (y/n)"
    if ($enableRDPProtection -eq 'y') {
        Write-Host "Configuring RDP protection..."
        Configure-RDPProtection
    }

    Read-Host "Press any key to exit"
} else {
    Write-Host "kavgui.exe is not running."

    # Add Windows Defender exclusion for C:\Program Files (x86)
    Write-Host "Adding exclusion for Windows Defender..."
    Add-MpPreference -ExclusionPath "C:\Program Files (x86)"

    # Ask user which setup to install
    $variant = Read-Host "Which antivirus variant do you want to install? (A+/Z+)"
    if ($variant -eq 'A+') {
        $url = "https://nextviewkavach.com/build/KavachA+.exe"
    } elseif ($variant -eq 'Z+') {
        $url = "https://nextviewkavach.com/build/KavachZ+.exe"
    } else {
        Write-Host "Invalid variant selected. Exiting."
        exit
    }

    # Generate a random folder name in AppData\Local
    $randomFolder = New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\$(New-Guid)"
    $installerPath = "$randomFolder\KavachInstaller.exe"

    # Download the installer with progress
    Write-Host "Downloading installer to $installerPath"
    Download-FileWithProgress -url $url -outputPath $installerPath

    # Run the installer
    Write-Host "Running the installer"
    Start-Process -FilePath $installerPath -Wait

    # Ask user about enabling various protections
    $enableProtection = Read-Host "Do you want to enable protections (ads, tracker, browser, malware, phishing, spying)? (y/n)"
    if ($enableProtection -eq 'y') {
        Write-Host "Enabling protections..."
        Configure-DNSProtection
        # Add your other protection enabling logic here
    }

    # Ask user if they want to apply RDP brute force protection
    $enableRDPProtection = Read-Host "Do you want to apply RDP brute force protection? (y/n)"
    if ($enableRDPProtection -eq 'y') {
        Write-Host "Configuring RDP protection..."
        Configure-RDPProtection
    }

    Read-Host "Press any key to exit"
}
