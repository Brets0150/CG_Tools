#Requires -RunAsAdministrator
<#
.SYNOPSIS
	This script will disable the PowerShell v2 Engine on Windows 10/11 or Server 2012/16/19/22, if any other version is detected no changes are made.
.DESCRIPTION
    This script will disable the PowerShell v2 Engine on Windows 10/11 or Server 2012/16/19/22.
    The script was meant to be run from a GPO startup script, but can be run manually as well.
.EXAMPLE
	PS> powershell.exe -ExecutionPolicy Bypass -NoProfile -NonInteractive -WindowsStyle Hidden .\Disable-PSv2.ps1
.LINK
	https://github.com/Brets0150/CG_Tools/
.NOTES
	Author: Bret.s / License: MIT
    Version: 1.0.0
#>

# Start logging
# Define the root Windows directory via environment variable.
$WindowsDir = $env:windir
$DefaultLogLocation = "$WindowsDir\Logs\DisablePSv2Log.txt"
Start-Transcript -Path $DefaultLogLocation

# Get the current OS version
$OSVersion = (get-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
# Disable PowerShell v2 based off the OS version
switch -regex ($OSVersion) {
    "(?i)10|2012|2016|2019|2022" {
        Write-Host "Windows 10/Server 2012/16/19/22 detected."
        Write-Host "Checking if PowerShell v2 is currently enabled..."
        $PSv2PreCheck = dism.exe /Online /Get-Featureinfo /FeatureName:"MicrosoftWindowsPowerShellv2" | findstr "State"
        If ( $PSv2PreCheck -like "State : Enabled" ) {
            Write-Host "PowerShell v2 appears to be enabled, disabling via dism..."
            dism.exe /Online /Disable-Feature /FeatureName:"MicrosoftWindowsPowerShellv2" /NoRestart
            $PSv2PostCheck = dism.exe /Online /Get-Featureinfo /FeatureName:"MicrosoftWindowsPowerShellv2" | findstr "State"
            If ( $PSv2PostCheck -like "State : Enabled" ) {
                Write-Host "PowerShell v2 still seems to be enabled, check the log for errors: $DefaultLogLocation"
            } Else {
                Write-Host "PowerShell v2 disabled successfully."
            }
        } Else {
            Write-Host "PowerShell v2 is already disabled, no changes will be made." -ForegroundColor Green
        }
    }
    "(?i)7|Vista|2008" {
        Write-Host "Detected Windows 7/Vista/Server 2008, no changes will be made." -ForegroundColor Green
    }
    default { Write-Host "Unable to match the OS, no changes will be made." -ForegroundColor Yellow }
}

#Stop logging
Stop-Transcript
