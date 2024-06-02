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

# Define URLs for the CMD/BAT file and EXE file
$cmdUrl = "https://raw.githubusercontent.com/nextviewkavach/download/main/kavrn%201.2.bat"
$exeUrl = "https://nextviewkavach.com/build/KavachA+Win7.exe"

# Define the destination paths
$cmdDestination = "$env:TEMP\kavrn_1.2.bat"
$exeDestination = "$env:TEMP\KavachA_Win7.exe"

# Download the CMD/BAT file with progress bar
Download-File -url $cmdUrl -destination $cmdDestination

# Execute the CMD/BAT file
Start-Process -FilePath $cmdDestination -Wait

# Download the EXE file with progress bar
Download-File -url $exeUrl -destination $exeDestination

# Execute the EXE file
Start-Process -FilePath $exeDestination -Wait
