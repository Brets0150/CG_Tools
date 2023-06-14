# Cisco Umbrella Deployment Script
# Author: Bret.s
# Known MD5 Hash of the MSI
[string]$KnownMsiMd5Hash = 'FAB243B46F241DC6B2291A4197D45561'
[string]$ORGID = ''
[string]$ORGFINGERPRINT = ''
[string]$USERID = ''

# Download Umbrella Roaming Client MSI
Invoke-WebRequest -Uri "https://disthost.umbrella.com/roaming/upgrade/win/stage/RoamingClient_WIN_3.0.351.msi" -OutFile "Setup.msi"

# Check if the downloaded MSI's MD5 hash matches the known hash, install the MSI file.
if ((Get-FileHash -Path "Setup.msi" -Algorithm MD5).Hash -eq $KnownMsiMd5Hash) {
    Write-Host "MD5 hash matches, installing MSI file."
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i Setup.msi /qn ORG_ID=$ORGID ORG_FINGERPRINT=$ORGFINGERPRINT USER_ID=$USERID HIDE_UI=1 HIDE_ARP=1" -Wait
    Write-Host "MSI file installed."
} else {
    Write-Host "MD5 hash does not match, exiting."
    Exit
}
exit 0