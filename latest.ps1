Add-Type -AssemblyName System.Windows.Forms

# Function to check if kavgui.exe is running
function Is-KavguiRunning {
    return (Get-Process -Name kavgui -ErrorAction SilentlyContinue) -ne $null
}

# Function to set DNS over HTTPS for Firefox
function Set-DNSOverHTTPSFirefox {
    $dnsServerUrl = "https://dns.dnswarden.com/00s8000000000000001000ivo"
    $profilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles\"

    if (Test-Path $profilesPath) {
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
    } else {
        Write-Output "Firefox is not installed."
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

    Write-Output "K-WebGuard configured for Google Chrome. Please restart Google Chrome to apply the changes."
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

    Write-Output "K-WebGuard configured for Google Chrome. Please restart Microsoft Edge to apply the changes."
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

# Function to download a file with progress
function Download-FileWithProgress {
    param (
        [string]$url,
        [string]$outputPath
    )

    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $outputPath)
        $webClient.Dispose()
    } catch {
        Write-Output "Failed to download file from $url"
    }
}

# Function to apply additional protection
function Apply-AdditionalProtection {
    $dnsServerUrl = "https://dns.dnswarden.com/00s8000000000000001000ivo"
    
    $enableFirefoxProtection = Read-Host "Do you want to enable K-WebGuard for Firefox? (y/n)"
    if ($enableFirefoxProtection -eq 'y') {
        try {
            Set-DNSOverHTTPSFirefox
        } catch {
            Write-Output "Failed to configure K-WebGuard for Firefox."
        }
    }

    $enableChromeProtection = Read-Host "Do you want to enable K-WebGuard for Google Chrome? (y/n)"
    if ($enableChromeProtection -eq 'y') {
        try {
            Configure-DNSOverHTTPSForChrome -dnsServerUrl $dnsServerUrl
        } catch {
            Write-Output "Failed to configure K-WebGuard for Google Chrome."
        }
    }

    $enableEdgeProtection = Read-Host "Do you want to enable K-WebGuard for Microsoft Edge? (y/n)"
    if ($enableEdgeProtection -eq 'y') {
        try {
            Configure-DNSOverHTTPSForEdge -dnsServerUrl $dnsServerUrl
        } catch {
            Write-Output "Failed to configure K-WebGuard for Microsoft Edge.."
        }
    }

    $enableRDPProtection = Read-Host "Do you want to apply RDP brute force protection? (y/n)"
    if ($enableRDPProtection -eq 'y') {
        try {
            Configure-RDPProtection
        } catch {
            Write-Output "Failed to configure RDP protection."
        }
    }
}

# Main logic
if (Is-KavguiRunning) {
    Write-Output "kavgui.exe is running."
    Apply-AdditionalProtection
} else {
    Write-Output "kavgui.exe is not running."

    try {
        Add-MpPreference -ExclusionPath "C:\Program Files (x86)"
    } catch {
        Write-Output "Failed to add exclusion path."
    }

    $installAntivirus = Read-Host "Do you want to install KAVACH antivirus? (y/n)"
    if ($installAntivirus -eq 'y') {
        $variant = Read-Host "Which antivirus variant do you want to install? (A+/Z+)"
        $url = if ($variant -eq 'A+') { "https://nextviewkavach.com/build/KavachA+.exe" } elseif ($variant -eq 'Z+') { "https://nextviewkavach.com/build/KavachZ+.exe" } else { Write-Output "Invalid variant selected. Exiting."; exit }

        try {
            $randomFolder = New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\$(New-Guid)" -ErrorAction Stop
            $installerPath = "$randomFolder\KavachInstaller.exe"

            Write-Output "Downloading installer to $installerPath"
            Download-FileWithProgress -url $url -outputPath $installerPath

            Write-Output "Running the installer"
            Start-Process -FilePath $installerPath -NoNewWindow
        } catch {
            Write-Output "Failed to download or run the installer."
        }

        Apply-AdditionalProtection
    } else {
        Write-Output "Antivirus installation skipped."
        Apply-AdditionalProtection
    }
}

Write-Output "Script execution completed."
