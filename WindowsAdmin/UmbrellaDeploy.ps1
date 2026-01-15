# Cisco Umbrella Deployment Script
# Author: Bret.s
# Version: 1.1

# Fill in your Umbrella Organization ID, Organization Fingerprint and User ID. This information can be found in the Umbrella Dashboard under Deployments > Core Identities.
[string]$ORGID = ''
[string]$ORGFINGERPRINT = ''
[string]$USERID = ''

# Define the Msi Install string.
# More Msi installer options can be found here: https://docs.umbrella.com/deployment-umbrella/docs/appendix-g-command-line-and-customization-for-installation.
[string]$InstallString = "/i Setup.msi /qn ORG_ID=$ORGID ORG_FINGERPRINT=$ORGFINGERPRINT USER_ID=$USERID HIDE_ARP=1"

# Get the current version of the Umbrella Roaming Client too compleate the downlaod URL.
[object]$JsonData = Invoke-RestMethod -Uri "https://disthost.umbrella.com/roaming/upgrade/win/production/manifest.json"

# Check if the JsonData is null or , "$JsonData.downloadFilename" or "$JsonData.downloadSHA1" is empty, if it is exit the script.
if ($null -eq $JsonData -or "$JsonData.downloadFilename" -eq "" -or "$JsonData.downloadSHA1" -eq "") {
    Write-Host "JsonData incomplete. Does the system have Internet access(IP + DNS)? Exiting."
    Exit
}

# Downlaod Uri for the Umbrella Roaming Client MSI.
[string]$MsiUri = "https://disthost.umbrella.com/roaming/upgrade/win/production/" + $JsonData.downloadFilename

# Download Umbrella Roaming Client MSI
Invoke-WebRequest -Uri "$MsiUri" -OutFile "Setup.msi"

# Check if the downloaded MSI's SHA1 hash matches the known hash, install the MSI file.
if ((Get-FileHash -Path "Setup.msi" -Algorithm SHA1).Hash -eq $JsonData.downloadSHA1) {
    Write-Host "SHA1 hash matches, installing MSI file."
    Start-Process -FilePath "msiexec.exe" -ArgumentList $InstallString -Wait
    Write-Host "MSI file installed."
} else {
    Write-Host "SHA1 hash does not match, exiting."
    Exit
}
exit 0