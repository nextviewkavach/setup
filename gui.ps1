Add-Type -AssemblyName System.Windows.Forms

# Function to check if kavgui.exe is running
function Is-KavguiRunning {
    return (Get-Process -Name kavgui -ErrorAction SilentlyContinue) -ne $null
}

# Function to set DNS over HTTPS for Firefox
function Set-DNSOverHTTPSFirefox {
    $dnsServerUrl = "https://dns.dnswarden.com/00s8000000000000001000ivo"
    $profilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles\"

    if (Test-Path -Path $profilesPath) {
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
        Write-Output "Firefox profiles directory not found. Skipping DNS over HTTPS configuration for Firefox."
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

    Write-Output "KAVACH WEB Protection configured for Google Chrome. Please restart Google Chrome to apply the changes."
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

    Write-Output "KAVACH WEB Protection configured for Microsoft Edge. Please restart Microsoft Edge to apply the changes."
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

    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url, $outputPath)
    $webClient.Dispose()
}

# Main logic
if (Is-KavguiRunning) {
    Write-Output "kavgui.exe is running."
    
    # Create the main form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "KAVACH Protection Options"
    $form.Size = New-Object System.Drawing.Size(400, 200)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

    # Create label
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Select an option:"
    $label.Location = New-Object System.Drawing.Point(10, 10)
    $label.Size = New-Object System.Drawing.Size(280, 20)
    $form.Controls.Add($label)

    # Create buttons
    $buttons = @()
    $buttonTexts = @(
        "Enable DNS over HTTPS for Firefox",
        "Enable DNS over HTTPS for Google Chrome",
        "Enable DNS over HTTPS for Microsoft Edge",
        "Configure RDP brute force protection"
    )
    $buttonLocations = @(30, 60, 90, 120)
    for ($i = 0; $i -lt $buttonTexts.Length; $i++) {
        $button = New-Object System.Windows.Forms.Button
        $button.Text = $buttonTexts[$i]
        $button.Location = New-Object System.Drawing.Point(10, $buttonLocations[$i])
        $button.Size = New-Object System.Drawing.Size(280, 20)
        $button.Add_Click({
            switch ($button.Text) {
                "Enable DNS over HTTPS for Firefox" {
                    Set-DNSOverHTTPSFirefox
                    Write-Output "DNS over HTTPS configured for Firefox."
                }
                "Enable DNS over HTTPS for Google Chrome" {
                    $dnsServerUrl = "https://dns.dnswarden.com/00s8000000000000001000ivo"
                    Configure-DNSOverHTTPSForChrome -dnsServerUrl $dnsServerUrl
                    Write-Output "DNS over HTTPS configured for Google Chrome."
                }
                "Enable DNS over HTTPS for Microsoft Edge" {
                    $dnsServerUrl = "https://dns.dnswarden.com/00s8000000000000001000ivo"
                    Configure-DNSOverHTTPSForEdge -dnsServerUrl $dnsServerUrl
                    Write-Output "DNS over HTTPS configured for Microsoft Edge."
                }
                "Configure RDP brute force protection" {
                    Configure-RDPProtection
                    Write-Output "RDP brute force protection configured."
                }
            }
        })
        $form.Controls.Add($button)
        $buttons += $button
    }

    # Create Cancel button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Location = New-Object System.Drawing.Point(10, 150)
    $cancelButton.Size = New-Object System.Drawing.Size(280, 20)
    $cancelButton.Add_Click({
        $form.Close()
    })
    $form.Controls.Add($cancelButton)

    $form.Topmost = $true
    $form.ShowDialog()
} else {
    Write-Output "kavgui.exe is not running."
    
    $installAntivirus = [System.Windows.Forms.MessageBox]::Show("Do you want to install KAVACH antivirus?", "Install Antivirus", [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($installAntivirus -eq [System.Windows.Forms.DialogResult]::Yes) {
        $variantForm = New-Object System.Windows.Forms.Form
        $variantForm.Text = "Select Variant"
        $variantForm.Size = New-Object System.Drawing.Size(300, 150)
        $variantForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

        $variantLabel = New-Object System.Windows.Forms.Label
        $variantLabel.Text = "Which antivirus variant do you want to install? (A+/Z+)"
        $variantLabel.Location = New-Object System.Drawing.Point(10, 10)
        $variantLabel.Size = New-Object System.Drawing.Size(280, 20)
        $variantForm.Controls.Add($variantLabel)

        $variantTextBox = New-Object System.Windows.Forms.TextBox
        $variantTextBox.Location = New-Object System.Drawing.Point(10, 40)
        $variantTextBox.Size = New-Object System.Drawing.Size(260, 20)
        $variantForm.Controls.Add($variantTextBox)

        $variantButton = New-Object System.Windows.Forms.Button
        $variantButton.Text = "OK"
        $variantButton.Location = New-Object System.Drawing.Point(10, 70)
        $variantButton.Size = New-Object System.Drawing.Size(60, 20)
        $variantButton.Add_Click({
            $variant = $variantTextBox.Text
            $variantForm.Close()

            $url = if ($variant -eq 'A+') { "https://nextviewkavach.com/build/KavachA+.exe" } elseif ($variant -eq 'Z+') { "https://nextviewkavach.com/build/KavachZ+.exe" } else { 
                [System.Windows.Forms.MessageBox]::Show("Invalid variant selected. Exiting.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK)
                return
            }

            $randomFolder = New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\$(New-Guid)"
            $installerPath = "$randomFolder\KavachInstaller.exe"

            Write-Output "Downloading installer to $installerPath"
            Download-FileWithProgress -url $url -outputPath $installerPath

            Write-Output "Running the installer"
            Start-Process -FilePath $installerPath -NoNewWindow

            $userChoice = [System.Windows.Forms.MessageBox]::Show("Press Yes to exit, Press No for more protection", "More Protection", [System.Windows.Forms.MessageBoxButtons]::YesNo)
            if ($userChoice -eq [System.Windows.Forms.DialogResult]::No) {
                $dnsServerUrl = "https://dns.dnswarden.com/00s8000000000000001000ivo"

                $enableProtection = [System.Windows.Forms.MessageBox]::Show("Do you want to enable Advance Web protection?", "Advance Web Protection", [System.Windows.Forms.MessageBoxButtons]::YesNo)
                if ($enableProtection -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Set-DNSOverHTTPSFirefox
                    Configure-DNSOverHTTPSForChrome -dnsServerUrl $dnsServerUrl
                    Configure-DNSOverHTTPSForEdge -dnsServerUrl $dnsServerUrl
                }

                $enableRDPProtection = [System.Windows.Forms.MessageBox]::Show("Do you want to apply RDP brute force protection?", "RDP Protection", [System.Windows.Forms.MessageBoxButtons]::YesNo)
                if ($enableRDPProtection -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Configure-RDPProtection
                }
            }
        })
        $variantForm.Controls.Add($variantButton)

        $variantForm.Topmost = $true
        $variantForm.ShowDialog()
    } else {
        Write-Output "Antivirus installation skipped."
    }
}

Read-Host "Press Enter to exit."
