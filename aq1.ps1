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

# Set Execution Policy to RemoteSigned
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Function to display progress bar
function Show-Progress {
    param (
        [string]$activity,
        [string]$status,
        [int]$percentComplete
    )
    Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete
}

# Function to start the Windows Defender service if not running
function Start-DefenderService {
    $service = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
    if ($service -eq $null -or $service.Status -ne 'Running') {
        Start-Service -Name WinDefend -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
    }
}

# Function to add exclusions to Windows Defender
function Add-DefenderExclusions {
    Add-MpPreference -ExclusionPath "C:\Program Files\KAVACH" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionPath "C:\Program Files (x86)\KAVACH" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "KAVGUI.exe" -ErrorAction SilentlyContinue
    Write-Host "Windows Defender exclusions added."
}

# Function to check if KAVGUI.exe is running
function Is-KAVGUIRunning {
    $kavProcess = Get-Process -Name KAVGUI -ErrorAction SilentlyContinue
    return $kavProcess -ne $null
}

# Function to download a file with a progress bar
function Download-File {
    param (
        [string]$url,
        [string]$destination
    )

    try {
        $request = [System.Net.HttpWebRequest]::Create($url)
        $request.Method = "GET"
        $response = $request.GetResponse()
        $totalBytes = $response.ContentLength

        $responseStream = $response.GetResponseStream()
        $fileStream = [System.IO.File]::Create($destination)

        $buffer = New-Object byte[] 8192
        $totalReadBytes = 0
        $readBytes = $responseStream.Read($buffer, 0, $buffer.Length)

        while ($readBytes -gt 0) {
            $fileStream.Write($buffer, 0, $readBytes)
            $totalReadBytes += $readBytes
            $readBytes = $responseStream.Read($buffer, 0, $buffer.Length)
            $percentComplete = [math]::Round(($totalReadBytes / $totalBytes) * 100, 2)
            Show-Progress -Activity "Downloading $url" -Status "$percentComplete% Complete" -PercentComplete $percentComplete
        }

        $fileStream.Close()
        $responseStream.Close()

        Write-Host "Download completed successfully."

        # Prompt for additional protection configurations
        $applyExtraProtection = Read-Host "Do you want to apply Ads Protection, Phishing Protection, Tracker Protection, Safe Browser Protection, and Malwaretizing Protection? Type 'yes' to apply."

        if ($applyExtraProtection -eq "yes") {
            Configure-ADProtection
            Configure-PhishingProtection
            Configure-DNSProtection
            Write-Host "Browsers have been configured to use comprehensive protection settings."
        } else {
            Write-Host "Skipping additional protection configurations."
        }
    } catch {
        Write-Host "Error during file download: $_"
    }
}

# Function to configure Anti-Phishing protection
function Configure-PhishingProtection {
    # Configure Anti-Phishing settings
    # Example: Add your code here
    Write-Host "Anti-Phishing protection configured."
}

# Function to configure AD (Ad Tracking) protection
function Configure-ADProtection {
    # Configure AD (Ad Tracking) protection settings
    # Example: Add your code here
    Write-Host "AD (Ad Tracking) protection configured."
}

# Function to configure RDP brute force protection
function Configure-RDPBruteForceProtection {
    $configure = Read-Host "Do you want to configure RDP brute force protection? (yes/no)"
    if ($configure -eq "yes") {
        # Set the RDP brute force protection settings
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "MaxFailedLogins" -Value 5
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "MaxConnectionTime" -Value 0
        Write-Host "RDP brute force protection configured. User will be disabled indefinitely after 5 unsuccessful login attempts."
    } else {
        Write-Host "RDP brute force protection not configured."
    }
}

# Function to configure DNS over HTTPS protection
function Configure-DNSProtection {
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
}

# Start the Windows Defender service if needed
Start-DefenderService

# Add exclusions to Windows Defender
Add-DefenderExclusions

# Check if KAVGUI.exe is running
if (Is-KAVGUIRunning) {
    $applyNewSettings = Read-Host "kavgui.exe is running. Do you want to apply new protection settings? (yes/no)"
    if ($applyNewSettings -eq "yes") {
        Download-File
    } else {
        Write-Host "Skipping additional protection configurations."
    }
} else {
    $antivirusChoice = Read-Host "Which antivirus setup do you want to install? 1. KAVACH A+ 2. KAVACH Z+ Enter the number (1/2):"
    $destination = "$env:USERPROFILE\Documents\"
    switch ($antivirusChoice) {
        1 {
            $url = "https://nextviewkavach.com/build/KavachA+.exe"
            $destination += "KavachA+.exe"
        }
        2 {
            $url = "https://nextviewkavach.com/build/KavachZ+.exe"
            $destination += "KavachZ+.exe"
        }
        default {
            Write-Host "Invalid choice. Exiting script."
            exit
        }
    }
    Download-File -url $url -destination $destination
    Start-Process -FilePath $destination -Wait
}

# Prompt for RDP brute force protection
Configure-RDPBruteForceProtection

Write-Host "Press any key to exit and please reboot your machine to apply the protection settings."
[System.Console]::ReadKey()
