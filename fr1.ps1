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

        if ($response.StatusCode -ne [System.Net.HttpStatusCode]::OK) {
            Write-Host "Failed to download file. Status code: $($response.StatusCode)"
            return $false
        }

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
        return $true
    }
    catch {
        Write-Host "Error occurred during download: $_"
        return $false
    }
}

# Function to install antivirus setup
function Install-Antivirus {
    param (
        [string]$setupName,
        [string]$setupUrl
    )

    # Download the setup file
    $setupPath = "C:\Temp\$setupName.exe"
    $downloaded = Download-File -url $setupUrl -destination $setupPath

    if ($downloaded) {
        # Install the antivirus
        Start-Process -FilePath $setupPath -Wait
    } else {
        Write-Host "Failed to download antivirus setup. Exiting..."
        exit
    }
}

# Start the Windows Defender service if needed
Start-DefenderService

# Check if KAVGUI.exe is running
if (Is-KAVGUIRunning) {
    Write-Host "kavgui.exe is running. Skipping antivirus setup installation."
} else {
    $setupChoice = Read-Host "KAVGUI.exe is not running. Which antivirus setup do you want to install?`n1. KAVACH A+`n2. KAVACH Z+`nEnter the number (1/2): "
    switch ($setupChoice) {
        '1' {
            Install-Antivirus -setupName "KavachA+.exe" -setupUrl "https://nextviewkavach.com/build/KavachA+.exe"
        }
        '2' {
            Install-Antivirus -setupName "KavachZ+.exe" -setupUrl "https://nextviewkavach.com/build/KavachZ+.exe"
        }
        default {
            Write-Host "Invalid selection. Exiting..."
            exit
        }
    }
}
