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

# Function to display ASCII animation
function Display-ASCII-Animation {
    $frames = @(
        "Kavach Advance Setup",
        "Kavach Advance Setup.",
        "Kavach Advance Setup..",
        "Kavach Advance Setup..."
    )

    for ($i = 0; $i -lt 3; $i++) {
        foreach ($frame in $frames) {
            Clear-Host
            Write-Host $frame
            Start-Sleep -Milliseconds 200
        }
    }
}

# Display the ASCII animation
Display-ASCII-Animation

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

# Function to configure DNS over HTTPS
function Configure-DNSOverHTTPS {
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

# Check if kavgui.exe is running
$kavachRunning = Get-Process -Name "kavgui" -ErrorAction SilentlyContinue

if ($kavachRunning) {
    # Kavach is already running, skip the download and installation part
    Write-Host "Kavach is already running. Skipping download and installation."
} else {
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

    # Confirm successful installation before proceeding
    if ($LASTEXITCODE -eq 0) {
        Write-Host "KAVACH installation completed successfully."
    } else {
        Write-Host "KAVACH installation failed. Please try again."
        exit
    }

    # Prompt for comprehensive protection configuration with colored text
    $protectionPrompt = @"
$(Write-Host "Do you want to apply comprehensive protection? This includes:" -ForegroundColor Yellow)
$(Write-Host "  - Phishing Protection" -ForegroundColor Green)
$(Write-Host "  - Ad Protection" -ForegroundColor White)
$(Write-Host "  - Surfing Protection" -ForegroundColor Green)
$(Write-Host "  - Tracker Protection" -ForegroundColor White)
$(Write-Host "  - Browser Speed Optimization" -ForegroundColor Green)
$(Write-Host "  - Malware Protection" -ForegroundColor White)
Enter 'y' for yes or 'n' for no:
"@

    $applyProtection = Read-Host -Prompt $protectionPrompt

    if ($applyProtection -eq "y") {
        # Apply DNS over HTTPS settings
        Configure-DNSOverHTTPS
    } else {
        Write-Host "Comprehensive protection settings not applied."
    }
}
