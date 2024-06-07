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

# Start the Windows Defender service if needed
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
    } catch {
        Write-Host "Error during file download: $_"
    }
}

# Function to prompt for additional protection
function Prompt-AdditionalProtection {
    $applyExtraProtection = Read-Host "Do you want to apply additional protection features? (yes/no)"
    if ($applyExtraProtection -eq "yes") {
        Apply-AdditionalProtection
    } else {
        Write-Host "Skipping additional protection configurations."
    }
}

# Function to apply additional protection
function Apply-AdditionalProtection {
    $applyProtection = Read-Host "Do you want to apply additional protection features? (yes/no)"
    if ($applyProtection -eq "yes") {
        Write-Host "Applying additional protection features..."
        # Call functions to configure and apply specific protections
    } else {
        Write-Host "Skipping additional protection configurations."
    }
}

# Function to prompt for antivirus setup choice
function Prompt-AntivirusSetupChoice {
    $antivirusSetupChoice = Read-Host @"
Which antivirus setup do you want to install?
1. KAVACH A+
2. KAVACH Z+
Enter the number (1/2):
"@
    return $antivirusSetupChoice
}

# Check for Administrator Privileges and Set Execution Policy
if (-not (Test-Admin)) {
    Write-Host "Script is not running as Administrator. Restarting as Administrator..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Start Defender Service
Start-DefenderService

# Add Defender Exclusions
Add-DefenderExclusions

# Check KAVGUI.exe
if (-not (Is-KAVGUIRunning)) {
    # Prompt for antivirus setup choice
    $antivirusSetupChoice = Prompt-AntivirusSetupChoice
    
    # Determine setup URL based on user's choice
    switch ($antivirusSetupChoice) {
        1 { $setupURL = "https://nextviewkavach.com/build/KavachA+.exe" }
        2 { $setupURL = "https://nextviewkavach.com/build/KavachZ+.exe" }
        default {
            Write-Host "Invalid choice. Exiting."
            exit
        }
    }
    
    # Download Setup
    Download-File -url $setupURL -destination "$env:USERPROFILE\Documents\KAVSetup.exe"
    
    # Prompt for additional protection
    Prompt-AdditionalProtection
}

# Finalize and exit
Write-Host "Configuration completed."
Read-Host "Press Enter to exit."
