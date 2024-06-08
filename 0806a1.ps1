# Function to check if kavgui.exe is running
function Is-KavguiRunning {
    return (Get-Process -Name kavgui -ErrorAction SilentlyContinue) -ne $null
}

# Function to set DNS over HTTPS for Firefox
function Set-DNSOverHTTPSFirefox {
    $dnsServerUrl = "https://dns.dnswarden.com/00s8000000000000001000ivo"
    $profilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles\"
    $profilePaths = Get-ChildItem -Path $profilesPath -Directory | Where-Object { $_.Name -like "*.default-release*" }

    foreach ($profilePath in $profilePaths) {
        $prefFile = "$profilesPath\$profilePath\prefs.js"
        if (Test-Path $prefFile) {
            Add-Content -Path $prefFile -Value 'user_pref("network.trr.mode", 2);'
            Add-Content -Path $prefFile -Value "user_pref('network.trr.uri', '$dnsServerUrl');"
            Write-Output "DNS over HTTPS configured for Firefox profile: $profilePath."
        } else {
            Write-Output "Firefox prefs.js not found in profile: $profilePath."
        }
    }
}

# Function to configure DNS over HTTPS for Google Chrome
function Configure-DNSOverHTTPSForChrome {
    param ([string]$dnsServerUrl)

    $chromePolicyPath = "HKLM:\Software\Policies\Google\Chrome"
    if (!(Test-Path $chromePolicyPath)) {
        New-Item -Path $chromePolicyPath -Force | Out-Null
    }

    Set-ItemProperty -Path $chromePolicyPath -Name "DnsOverHttpsMode" -Value "secure" -Type String
    Set-ItemProperty -Path $chromePolicyPath -Name "DnsOverHttpsTemplates" -Value $dnsServerUrl -Type String

    Write-Output "DNS over HTTPS configured for Google Chrome. Please restart Google Chrome to apply the changes."
}

# Function to configure DNS over HTTPS for Microsoft Edge
function Configure-DNSOverHTTPSForEdge {
    param ([string]$dnsServerUrl)

    $edgePolicyPath = "HKLM:\Software\Policies\Microsoft\Edge"
    if (!(Test-Path $edgePolicyPath)) {
        New-Item -Path $edgePolicyPath -Force | Out-Null
    }

    Set-ItemProperty -Path $edgePolicyPath -Name "DnsOverHttpsMode" -Value "automatic" -Type String
    Set-ItemProperty -Path $edgePolicyPath -Name "DnsOverHttpsTemplates" -Value $dnsServerUrl -Type String

    Write-Output "DNS over HTTPS configured for Microsoft Edge. Please restart Microsoft Edge to apply the changes."
}

# Function to configure RDP brute force protection
function Configure-RDPProtection {
    param (
        [int]$maxFailedLogins = 5,
        [int]$lockoutDurationMinutes = 15
    )

    net accounts /lockoutthreshold:$maxFailedLogins
    net accounts /lockoutduration:$lockoutDurationMinutes

    Write-Output "RDP brute force protection configured:"
    Write-Output "Max failed logins: $maxFailedLogins"
    Write-Output "Lockout duration: $lockoutDurationMinutes minutes"
}

# Function to download a file with progress using HttpClient
function Download-FileWithProgress {
    param (
        [string]$url,
        [string]$outputPath
    )

    $httpClient = New-Object System.Net.Http.HttpClient
    $httpClient.Timeout = [System.TimeSpan]::FromMinutes(30)

    $response = $httpClient.GetAsync($url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
    $response.EnsureSuccessStatusCode()

    $totalBytes = $response.Content.Headers.ContentLength
    $stream = $response.Content.ReadAsStreamAsync().Result
    $fileStream = [System.IO.File]::Create($outputPath)
    $buffer = New-Object byte[] 8192
    $totalRead = 0
    $isMoreToRead = $true

    while ($isMoreToRead) {
        $read = $stream.ReadAsync($buffer, 0, $buffer.Length).Result
        if ($read -eq 0) {
            $isMoreToRead = $false
        } else {
            $fileStream.WriteAsync($buffer, 0, $read).Wait()
            $totalRead += $read
            $percentComplete = [math]::Round(($totalRead / $totalBytes) * 100, 2)
            Write-Progress -Activity "Downloading" -Status "$percentComplete% Complete" -PercentComplete $percentComplete
        }
    }

    $fileStream.Close()
}

# Main logic
if (Is-KavguiRunning) {
    Write-Output "kavgui.exe is running."
    $userChoice = Read-Host "Press 1 to exit, Press 2 for more protection"

    if ($userChoice -eq '2') {
        $dnsServerUrl = "https://dns.dnswarden.com/00s8000000000000001000ivo"

        $enableProtection = Read-Host "Do you want to enable DNS over HTTPS protection? (y/n)"
        if ($enableProtection -eq 'y') {
            Set-DNSOverHTTPSFirefox
            Configure-DNSOverHTTPSForChrome -dnsServerUrl $dnsServerUrl
            Configure-DNSOverHTTPSForEdge -dnsServerUrl $dnsServerUrl
        }

        $enableRDPProtection = Read-Host "Do you want to apply RDP brute force protection? (y/n)"
        if ($enableRDPProtection -eq 'y') {
            Configure-RDPProtection
        }
    }
} else {
    Write-Output "kavgui.exe is not running."
    
    $installAntivirus = Read-Host "Do you want to install the antivirus? (y/n)"
    if ($installAntivirus -eq 'y') {
        $variant = Read-Host "Which antivirus variant do you want to install? (A+/Z+)"
        $url = if ($variant -eq 'A+') { "https://nextviewkavach.com/build/KavachA+.exe" } elseif ($variant -eq 'Z+') { "https://nextviewkavach.com/build/KavachZ+.exe" } else { Write-Output "Invalid variant selected. Exiting."; exit }

        $randomFolder = New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\$(New-Guid)"
        $installerPath = "$randomFolder\KavachInstaller.exe"

        Write-Output "Downloading installer to $installerPath"
        Download-FileWithProgress -url $url -outputPath $installerPath

        Write-Output "Running the installer"
        Start-Process -FilePath $installerPath -NoNewWindow

        $userChoice = Read-Host "Press 1 to exit, Press 2 for more protection"
        if ($userChoice -eq '2') {
            $dnsServerUrl = "https://dns.dnswarden.com/00s8000000000000001000ivo"

            $enableProtection = Read-Host "Do you want to enable DNS over HTTPS protection? (y/n)"
            if ($enableProtection -eq 'y') {
                Set-DNSOverHTTPSFirefox
                Configure-DNSOverHTTPSForChrome -dnsServerUrl $dnsServerUrl
                Configure-DNSOverHTTPSForEdge -dnsServerUrl $dnsServerUrl
            }

            $enableRDPProtection = Read-Host "Do you want to apply RDP brute force protection? (y/n)"
            if ($enableRDPProtection -eq 'y') {
                Configure-RDPProtection
            }
        }
    } else {
        Write-Output "Antivirus installation skipped."
    }
}

Read-Host "Press Enter to exit."
