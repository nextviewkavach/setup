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

# Start Windows Defender Service if not running
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
        Write-Progress -Activity "Downloading $url" -Status "$percentComplete% Complete" -PercentComplete $percentComplete
    }

    $fileStream.Close()
    $responseStream.Close()

    Write-Host "Download completed successfully."
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
