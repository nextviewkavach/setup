# Check for Administrator Privileges
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (Test-Admin)) {
    Write-Host "Script is not running as Administrator. Restarting as Administrator..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Add Exclusion Path to Windows Defender
Add-MpPreference -ExclusionPath 'C:\Program Files (x86)\'

# URL of the EXE file to download
$exeUrl = "https://nextviewkavach.com/build/KavachA+Win7.exe"
# Destination path for the downloaded EXE file
$exeDestination = "$env:TEMP\KavachA_Win7.exe"

# Function to download a file with a progress bar
function Download-File {
    param (
        [string]$url,
        [string]$destination
    )

    # Create a WebClient object
    $webClient = New-Object System.Net.WebClient

    # Event handler to update the progress bar
    $webClient.DownloadProgressChanged += {
        param ($sender, $e)
        Write-Progress -Activity "Downloading $url" -Status "$($e.ProgressPercentage)% Complete" -PercentComplete $e.ProgressPercentage
    }

    # Download the file
    $webClient.DownloadFile($url, $destination)
}

# Download the EXE file with progress bar
Download-File -url $exeUrl -destination $exeDestination

# Execute the EXE file
Start-Process -FilePath $exeDestination -Wait
