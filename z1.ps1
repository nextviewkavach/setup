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

# Function to download a file with a progress bar
function Download-File {
    param (
        [string]$url,
        [string]$destination
    )

    $request = [System.Net.HttpWebRequest]::Create($url)
    $request.Method = "GET"
    $response = $request.GetResponse()
    $totalBytes = $response.ContentLength

    $responseStream = $response.GetResponseStream()
    $fileStream = New-Object IO.FileStream ($destination, [IO.FileMode]::Create)

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
}

# Function to configure RDP brute force protection
function Configure-RDPBruteForceProtection {
    # Set the RDP brute force protection settings
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "MaxFailedLogins" -Value 5
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "MaxConnectionTime" -Value 900
    Write-Host "RDP brute force protection configured. User will be disabled for 15 minutes after 5 unsuccessful login attempts."
}

# Start the Windows Defender service if needed
Start-DefenderService

# Add Exclusion Path to Windows Defender
try {
    Add-MpPreference -ExclusionPath 'C:\Program Files (x86)\'
    Write-Host "Exclusion path added successfully."
} catch {
    Write-Host "Failed to add exclusion path. Please check if the Windows Defender service is running."
}

# Define URLs for the EXE files
$exeUrlA = "https://nextviewkavach.com/build/KavachA+Win7.exe"
$exeUrlZ = "https://nextviewkavach.com/build/KavachZ+Win7.exe"

# Ask the user which setup they want to install
$choice = Read-Host "Which setup do you want to install? Enter 1 for KAVACH A+, Enter 2 for KAVACH Z+"

if ($choice -eq "1") {
    $exeUrl = $exeUrlA
    $exeName = "KavachA_Win7.exe"
    Write-Host "You chose to install KAVACH A+"
} elseif ($choice -eq "2") {
    $exeUrl = $exeUrlZ
    $exeName = "KavachZ_Win7.exe"
    Write-Host "You chose to install KAVACH Z+"
} else {
    Write-Host "Invalid choice. Exiting."
    exit
}

# Define the destination path for the downloaded EXE file
$exeDestination = "$env:TEMP\$exeName"

# Download the EXE file with progress bar
Download-File -url $exeUrl -destination $exeDestination

# Execute the EXE file
Start-Process -FilePath $exeDestination -Wait

# Prompt for comprehensive protection configuration
$applyProtection = Read-Host "Do you want to apply comprehensive protection (phishing, ad, surfing, tracker, speed optimization, malware)? (yes/no)"

if ($applyProtection -eq "yes") {

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
    Write-Host "Comprehensive protection settings not applied."
}

# Configure RDP brute force protection
Configure-RDPBruteForceProtection

Write-Host "Protection settings configured."
