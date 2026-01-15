#Ask the use to input the Nextcloud URL and the Share Token link to the publicly shared folder.
$nextcloudUrl = Read-Host "Enter the Nextcloud URL(Example: `"https://drive.acme.com/s/XSjjFzwKodG1B4b`")"
# Set security protocol to TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Ask the user to input the file they want to upload to the Nextcloud server.
$file = Read-Host "Enter the path to the file you want to upload to Nextcloud(Example: `"C:\file.zip`")"
# Take the user provided nextcloud URL, extract the share token at the end of the URL and store it in the $sharetoken variable.
$sharetoken = $nextcloudUrl -replace '.*\/s\/(.*)', '$1'
# Exxtract the root URL of the Nextcloud server and store it in the $nextcloudUrl variable.
$nextcloudUrl = $nextcloudUrl -replace '(.*)\/s\/.*', '$1'
# Retrieve file object
$fileObject = Get-Item $file
# Define headers for HTTP request
$headers = @{
    "Authorization"=$("Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($("$($sharetoken):"))))");
    "X-Requested-With"="XMLHttpRequest";
}
# Construct URL for webdav endpoint
$webdavUrl = "$($nextcloudUrl)/public.php/webdav/$($fileObject.Name)"
# Upload file to Nextcloud server
Invoke-RestMethod -Uri $webdavUrl -InFile $fileObject.Fullname -Headers $headers -Method Put