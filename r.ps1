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

# Function to remove DNS over HTTPS settings
function Remove-DNSOverHTTPS {
    # Remove protection settings for Chrome and Edge
    function Remove-Protection-ChromeEdge {
        param (
            [string]$browser
        )

        $registryPath = "HKLM:\Software\Policies\Microsoft\$browser"
        if (Test-Path $registryPath) {
            Remove-ItemProperty -Path $registryPath -Name "DnsOverHttpsMode" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $registryPath -Name "DnsOverHttpsTemplates" -ErrorAction SilentlyContinue
            Write-Host "$browser protection settings removed."
        } else {
            Write-Host "$browser protection settings not found."
        }
    }

    # Remove protection settings for Chrome
    Remove-Protection-ChromeEdge -browser "Chrome"

    # Remove protection settings for Edge
    Remove-Protection-ChromeEdge -browser "Edge"

    # Remove protection settings for Firefox
    function Remove-Protection-Firefox {
        $firefoxProfilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles\"
        if (Test-Path $firefoxProfilesPath) {
            $profiles = Get-ChildItem $firefoxProfilesPath -Directory
            foreach ($profile in $profiles) {
                $prefsFile = "$firefoxProfilesPath\$profile\prefs.js"
                if (Test-Path $prefsFile) {
                    $prefsContent = Get-Content -Path $prefsFile
                    $prefsContent = $prefsContent | Where-Object { $_ -notmatch "network.trr.mode" -and $_ -notmatch "network.trr.uri" }
                    $prefsContent | Set-Content -Path $prefsFile
                    Write-Host "Firefox profile $profile protection settings removed."
                }
            }
        } else {
            Write-Host "Firefox profiles not found."
        }
    }

    # Remove protection settings for Firefox
    Remove-Protection-Firefox
}

# Check if kavgui.exe is running
$kavachRunning = Get-Process -Name "kavgui" -ErrorAction SilentlyContinue

if ($kavachRunning) {
    # Do nothing, just continue to the DNS configuration part
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
}

# Remove DNS over HTTPS settings
Remove-DNSOverHTTPS

Write-Host "Protection settings removed from browsers."
