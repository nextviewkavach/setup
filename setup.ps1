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

# Add Exclusion Path to Windows Defender
Add-MpPreference -ExclusionPath 'C:\Program Files (x86)\'

# Download the EXE file with progress bar
Download-File -url $exeUrl -destination $exeDestination

# Execute the EXE file
Start-Process -FilePath $exeDestination -Wait
