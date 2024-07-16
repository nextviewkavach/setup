# Define the registry path for Chrome policies
$registryPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"

# Ensure the registry path exists
if (-Not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

# Set the DNS-over-HTTPS mode to "secure"
Set-ItemProperty -Path $registryPath -Name "DnsOverHttpsMode" -Value "secure"

# Set the DNS-over-HTTPS templates to the specified DNS server URL
Set-ItemProperty -Path $registryPath -Name "DnsOverHttpsTemplates" -Value "https://dns.dnswarden.com/0000000000000000000000804"

Write-Output "web protection is now enabled."
