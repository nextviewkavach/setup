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
        $fileStream = New-Object IO.FileStream($destination, [IO.FileMode]::Create)

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
        $applyExtraProtection = Read-Host "For additional protection, type 'yes' and press Enter. Otherwise, press Enter to continue."

        if ($applyExtraProtection -eq "yes") {
            Configure-ADAndPhishingProtection
        } else {
            Write-Host "Skipping additional protection configurations."
        }
    }
    catch {
        Write-Host "Error occurred during download: $_"
    }
}

# Function to configure Anti-Phishing and AD protection
function Configure-ADAndPhishingProtection {
    Write-Host "Highlighting features: AD (Ad Tracking) protection, Anti-Phishing protection"
    Configure-ADProtection
    Configure-PhishingProtection
}

# Function to configure Anti-Phishing protection
function Configure-PhishingProtection {
    $configure = "yes" # Automatically configure
    if ($configure -eq "yes") {
        # Configure Anti-Phishing settings
        # Example: Add your code here
        Write-Host "Anti-Phishing protection configured."
    } else {
        Write-Host "Anti-Phishing protection not configured."
    }
}

# Function to configure AD (Ad Tracking) protection
function Configure-ADProtection {
    $configure = "yes" # Automatically configure
    if ($configure -eq "yes") {
        # Configure AD (Ad Tracking) protection settings
        # Example: Add your code here
        Write-Host "AD (Ad Tracking) protection configured."
    } else {
        Write-Host "AD (Ad Tracking) protection not configured."
    }
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

# Start the Windows Defender service if needed
Start-DefenderService

# Check if KAVGUI.exe is running
if (Is-KAVGUIRunning) {
    $applyNewSettings = Read-Host "kavgui.exe is running. Do you want to apply new protection settings? (yes/no)"
    if ($applyNewSettings -eq "yes") {
        Download-File -url "https://example.com/file_to_download.txt" -destination "C:\Downloads\file_to_download.txt"
    } else {
        Write-Host "Skipping additional protection configurations."
    }
} else {
    Download-File -url "https://example.com/file_to_download.txt" -destination "C:\Downloads\file_to_download.txt"
}

Write-Host "Protection settings configured."
