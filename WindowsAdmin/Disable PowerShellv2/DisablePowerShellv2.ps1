#Requires -RunAsAdministrator
<#
.SYNOPSIS
	This script will disable the PowerShell v2 Engine on Windows 10/11 or Server 2012/16/19/22, if any other version is detected no changes are made.
.DESCRIPTION
    This script will disable the PowerShell v2 Engine on Windows 10/11 or Server 2012/16/19/22.
    The script was meant to be run from a GPO startup script, but can be run manually as well.
    Here is an overview of what the script does:
        1. Starts logging by defining the path for the log file.
        2. Determines the version of the operating system running on the machine.
        3. Checks if the version of PowerShell v2 is enabled based on the operating system version.
        4. If PowerShell v2 is enabled, it disables the feature and logs whether the process was successful or not.
        5. If PowerShell v2 is already disabled, it logs a message indicating no changes will be made.
        6. Stops logging.
    See my blog post for more details: https://cybergladius.com/powershell-best-practices-for-preventing-abuse/#remove-powershell-v2
.EXAMPLE
	PS> powershell.exe -ExecutionPolicy Bypass -NoProfile -NonInteractive -WindowsStyle Hidden ./DisablePowerShellv2.ps1
.LINK
	https://github.com/Brets0150/CG_Tools/blob/main/WindowsAdmin/Disable%20PowerShellv2/DisablePowerShellv2.ps1
.NOTES
	Author: Bret.s / License: MIT
    Version: 1.0.0
#>

# Start logging
[string]$WindowsDir = $env:windir
[string]$logPath = Join-Path $WindowsDir "Logs\DisablePSv2Log.txt"
[string]$global:featureName = "MicrosoftWindowsPowerShellv2"
Start-Transcript -Path $logPath -Append -NoClobber

# Get the current OS version
[string]$osVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName

# A function that will Get the status of the PowerShell v2 feature installaion.
function Get-PowerShellv2Status {
    [object]$PSv2Status = Get-WindowsOptionalFeature -Online -FeatureName $global:featureName
    return $PSv2Status
}

# Disable PowerShell v2 based off the OS version
switch -regex ($osVersion) {
    # If the OS version is 10, 2012, 2016, 2019 or 2022:
    "(?i)10|2012|2016|2019|2022" {
        Write-Host "Windows 10/Server 2012/16/19/22 detected."
        Write-Host "Checking if PowerShell v2 is currently enabled..."

        if ((Get-PowerShellv2Status).State -eq "Enabled") {
            # If PowerShell v2 is enabled, disable it.
            Write-Host "PowerShell v2 appears to be enabled, disabling..."
            # Using  Disable-WindowsOptionalFeature PowerShell command does not seem to work in a startup script, so using Dism instead.
            Dism.exe /Online /Disable-Feature /FeatureName:$global:featureName
            # Old Version:  Disable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart

            if ((Get-PowerShellv2Status).State-eq "Enabled") {
                # If PowerShell v2 is still enabled, log an error
                Write-Host "PowerShell v2 still seems to be enabled, check the log for errors: $logPath"
            } else {
                # If PowerShell v2 is successfully disabled, log a success message
                Write-Host "PowerShell v2 disabled successfully."
            }
        } else {
            # If PowerShell v2 is already disabled, log a message indicating no changes will be made
            Write-Host "PowerShell v2 is already disabled, no changes will be made." -ForegroundColor Green
        }
    }
    # If the OS version is 7, Vista, or 2008:
    "(?i)7|Vista|2008" {
        # Log a message indicating no changes will be made
        Write-Host "Detected Windows 7/Vista/Server 2008, no changes will be made." -ForegroundColor Green
    }
    default {
        # If the OS version cannot be matched, log a message indicating no changes will be made
        Write-Host "Unable to match the OS, no changes will be made." -ForegroundColor Yellow
    }
}

# Stop logging
Stop-Transcript
