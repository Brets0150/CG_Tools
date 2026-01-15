#Requires -RunAsAdministrator
<#
.SYNOPSIS
	A script to deploy Sysmon via GPO.
.DESCRIPTION
    This PowerShell script will automatically download, install, and configure(using the SwiftOnSecurity Sysmon config) the latest version of the Sysmon.
	This script is designed to be deployed via a "Start-up" script GPO. Every time the computer starts, it will check if the Sysmon is installed,
	the latest version, and is it running. If it is not installed, install it. If it is not the latest version, update it. If it is not running, start it.
.EXAMPLE
	PS> Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
	PS> Invoke-WebRequest https://github.com/Brets0150/CG_BlueTeamTools/blob/main/SysmonGpoDeploy.ps1 -O .\SysmonGpoDeploy.ps1
	PS> ./SysmonGpoLogging.ps1
.LINK
	https://github.com/Brets0150/CG_BlueTeamTools/blob/main/SysmonGpoLogging.ps1
.NOTES
	Author: Bret.s / License: MIT - Last Updated: 2024-1-25
	---Updates---
	2024-1-25 - Initial creation of the script.
	2024-9-5 - Added debugging messages to the script. Added a reinstall of Sysmon if the service fails to start, but the executable is found.
#>

#====================================================================================================================
# Global Variables
[string]$global:SysmonProcessName = "Sysmon64"
[string]$global:SysmonExeFileName = "Sysmon64.exe"
[string]$global:Sysmon_TempDir = "$env:temp\Sysmon\" # This is the directory the Sysmon installer will extract to.
[string]$global:SysmonConfig_Temp = "$global:Sysmon_TempDir" + "sysmon-config.xml"
[string]$global:SysmonExe_Temp = "$global:Sysmon_TempDir" + "$global:SysmonExeFileName"
[string]$global:SysmonConfig = "C:\Windows\" + "sysmon-config.xml"
[string]$global:SysmonExe = "C:\Windows\" + "$global:SysmonExeFileName"
[bool]$global:debug = $true
#====================================================================================================================
function Get-SysmonVersion {
	<#
	.SYNOPSIS
		Get the version number of the Sysmon executable.
	.DESCRIPTION
		This function will run the Sysmon executable with the -h flag and parse the output for the version number.
	.EXAMPLE
		PS> Get-SysmonVersion
	.OUTPUTS
		[float] The version number of the Sysmon executable.
	#>

	# Run the Sysmon executable with the -h flag and put the output into a variable.
	[string]$SysmonOutput = & $global:SysmonExe -h 2>&1

	# Parse the text for the version number.
	[string]$SysmonVersion = [regex]::Match($SysmonOutput, 'v\d+\.\d+').Value

	# Remove the 'v' from the version number.
	[float]$SysmonVersion = $SysmonVersion.Substring(1)
	# Return the version number.
	return $SysmonVersion
}

Function Get-SysmonStatus {
	<#
	.SYNOPSIS
		Get the status of the Sysmon service.
	.DESCRIPTION
		This function will check the status of the Sysmon service and return true if it is running, false if it is not.
	.EXAMPLE
		PS> Get-SysmonStatus
	.OUTPUTS
		[bool] True if the Sysmon service is running, false if it is not.
	#>

	[string]$SysmonServiceName = (Get-Service | Where-Object {$_.DisplayName -like "*Sysmon*"}).Name

	Try {
		# Get the status of the Sysmon service.
		[string]$SysmonStatus = Get-Service $SysmonServiceName -ErrorAction SilentlyContinue  | Select-Object -ExpandProperty Status
		# If the status is running, return true.
		if ($SysmonStatus -eq "Running") {
			return $true
		}
		if ($SysmonStatus -ne "Running") {
			return $false
		}
	}
	# Catch any errors.
	Catch {
		# If there was an error, return false.
		return $false
	}
}

function Get-NetworkStatus {
	<#
	.SYNOPSIS
		Get the status of the connection to the internet.
	.DESCRIPTION
		Check if the computer has a connection to the internet. Test if an internet address can be pinged, then test if a domain name can be resolved. If both tests pass, return true, if either test fails, return false.
	.EXAMPLE
		PS> Get-NetworkStatus
	.OUTPUTS
		[bool] True if the computer has a connection to the internet, false if it does not.
	#>

	[string]$DnsName = "google.com"
	[string]$IpAddress = "8.8.8.8"
	try {
		# Test if an internet address can be pinged.
		$PingTest = Test-Connection -ComputerName $IpAddress -Count 3 -Quiet -ErrorAction SilentlyContinue
		# If ping good, test DNS
		if ($PingTest) {
			# Test if a domain name can be resolved.
			(Resolve-DnsName -Name $DnsName -ErrorAction Stop) | Out-Null
			# If DNS good, return true.
			return $true
		} else {
			return $false
		}
	} catch {
		# If DNS fails to resolve, it will throw a stop action, triggering the catch.
		return $false
	}
}

function Get-SysmonLatestReleaseVersion {
	<#
	.SYNOPSIS
		Check the sysinternals website for the latest version of the Sysmon.
	.DESCRIPTION
		This function will check the sysinternals website for the latest version of the Sysmon.
	.EXAMPLE
		PS> Example
	.OUTPUTS
		[bool] True if the computer has a connection to the internet, false if it does not.
	#>

	# Set the TLS setting for the web request.
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	# Get the latest version of the Sysmon from the sysinternals website.
	[string]$SysmonUrl = "https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon"

	# Get the web content from the sysinternals website.
	try {
		$SysmonWebContent = Invoke-WebRequest -Uri $SysmonUrl -UseBasicParsing
		$SysmonVersion = $SysmonWebContent.Content -match 'Sysmon v(\d+\.\d+)'
		if ($SysmonVersion) {
			 return [float]$($matches[1])
		} else {
			return [float]0
		}
	} catch {
		"Error accessing URL: $_"
		return [float]0
	}
}

Function Get-SysmonUpdateRequired {
	<#
	.SYNOPSIS
		Compare the current version of the Sysmon to the latest version of the Sysmon.
	.DESCRIPTION
		Compares the current version of the Sysmon to the latest version of the Sysmon. If there is a newer version of the Sysmon available, return true, if there is not a newer version available, return false.
	.EXAMPLE
		PS> Get-SysmonUpdateRequired
	.OUTPUTS
		[bool] True if the current version of the Sysmon is less than the latest version of the Sysmon, false if it is not.
	#>

	# Get the current version of the Sysmon.
	[float]$SysmonCurrentVersion = Get-SysmonVersion

	if ($global:debug) {Write-Host "Installed Sysmon Version: $SysmonCurrentVersion" -ForegroundColor Yellow }

	# Get the latest version of the Sysmon.
	[float]$SysmonLatestVersion = Get-SysmonLatestReleaseVersion

	if ($global:debug) {Write-Host "Available Sysmon Version: $SysmonLatestVersion" -ForegroundColor Yellow }

	# Compare the current version of the Sysmon to the latest version of the Sysmon.
	if ($SysmonCurrentVersion -lt $SysmonLatestVersion) {
		return $true
	} else {
		return $false
	}
}

Function Get-SwiftOnSecuritySysmonConfig {
	<#
	.SYNOPSIS
		Get the SwiftOnSecurity Sysmon configuration file.
	.DESCRIPTION
		This function will download the SwiftOnSecurity Sysmon configuration file from the GitHub repository.
	.EXAMPLE
		PS> Get-SwiftOnSecuritySysmonConfig
	.OUTPUTS
		[string] The SwiftOnSecurity Sysmon configuration file.
	#>

	# Check if the computer has a connection to the internet.
	if (!(Get-NetworkStatus)) {
		throw "Error: No internet connection."
		Exit 1
	}

	# Set the TLS setting for the web request.
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	# Get the SwiftOnSecurity Sysmon configuration file from the GitHub repository.
	[string]$SwiftOnSecuritySysmonConfigUrl = "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml"

	# Get the web content from the GitHub repository.
	try {
		$SwiftOnSecuritySysmonConfig = Invoke-WebRequest -Uri $SwiftOnSecuritySysmonConfigUrl -UseBasicParsing
		return [string]$($SwiftOnSecuritySysmonConfig.Content)
	} catch {
		"Error accessing URL: $_"
		return $null
	}
}

function Install-Sysmon {
	<#
	.SYNOPSIS
		Downlaod, install, and configure the latest version of the Sysmon.]
	.DESCRIPTION
		This function will download, install, and configure the latest version of the Sysmon.
	.EXAMPLE
		PS> Install-Sysmon
	.OUTPUTS
		[bool] True if the Sysmon was installed successfully, false if it was not.
	#>

	# Download the Sysmon installer
	[string]$SysmonInstallerZip = "Sysmon.zip"
	[string]$SysmonUrl = "https://download.sysinternals.com/files/Sysmon.zip"
	[string]$SysmonZipFile = "$global:Sysmon_TempDir" + "$SysmonInstallerZip"

	# Step 0
	# Check if the computer has a connection to the internet.
	if (!(Get-NetworkStatus)) {
		throw "Error: No internet connection."
		Exit 1
	}

	# Step 1
	# Check if Sysmon Zip exists, if not download it.
	if (!(Test-Path $SysmonZipFile)) {
		Try {
			# Create the temp directory for the Sysmon installer.
			New-Item -Path $global:Sysmon_TempDir -ItemType Directory -Force
			# Download the Sysmon installer.
			[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
			Invoke-WebRequest -Uri $SysmonUrl -OutFile $SysmonZipFile
		} catch {
			throw "Error downloading Sysmon installer."
			Exit 1
		}
		# Confirm the Sysmon zip was downloaded.
		if (!(Test-Path $SysmonZipFile)) {
			throw "Sysmon installer failed to download."
			Exit 1
		}
	}

	# Step 2
	# Now that we have Sysmon Zip, extract it and move the Sysmon64.exe to the Windows System32 directory.
	try {
		# Extract the downloaded zip file to the temp directory.
		Expand-Archive -Path $SysmonZipFile -DestinationPath $global:Sysmon_TempDir -Force

		# Confirm the Sysmon installer was extracted.
		if (!(Test-Path $global:SysmonExe_Temp)) {
			throw  "Sysmon installer failed to extract."
			Exit 1
		}

		# Move the Sysmon64.exe to the Windows System32 directory.
		Copy-Item -Path $global:SysmonExe_Temp -Destination $global:SysmonExe -Force

		#Confirm the Sysmon64.exe was moved successfully. If not exit with error.
		if (!(Test-Path $global:SysmonExe)) {
			throw "Error moving Sysmon64.exe to the Windows System32 directory."
			Exit 1
		}
		# Delete the Sysmon installer temp directory.
		Remove-Item $global:Sysmon_TempDir -Force -Recurse -ErrorAction SilentlyContinue
	}
	catch {
		throw  "Sysmon installer failed to extract and move."
	}

	# Step 3
	# Get and install the Sysmon Config.
	[string]$SysmonConfig = Get-SwiftOnSecuritySysmonConfig

	# If the Sysmon Config is null, exit with error.
	if ($null -eq $SysmonConfig) {
		throw "Error getting Sysmon Config."
		Exit 1
	}

	# Check if there is an existing Sysmon Config file, if so compare it to the new Sysmon Config file.
	if (Test-Path $global:SysmonConfig) {
		# Get the existing Sysmon Config file.
		[string]$ExistingSysmonConfig = Get-Content $global:SysmonConfig
		# Compare the existing Sysmon Config file to the new Sysmon Config file.
		if ($SysmonConfig -ne $ExistingSysmonConfig) {
			# The Sysmon Config files are different, write the new config to the file.
			# Write the Sysmon Config to the $global:SysmonConfig file.
			$SysmonConfig | Out-File -FilePath $global:SysmonConfig -Encoding ascii -Force
		}
	} elseif (!(Test-Path $global:SysmonConfig)) {
		# No existing config found, write the new config to the file.
		# Write the Sysmon Config to the $global:SysmonConfig file.
		$SysmonConfig | Out-File -FilePath $global:SysmonConfig -Encoding ascii -Force
	}

	# Confirm the Sysmon Config was written to the file.
	if (!(Test-Path $global:SysmonConfig)) {
		throw "Error writing Sysmon Config to file."
		Exit 1
	}

	# Step 4
	# Install Sysmon: All the files are inplace, we now need to tell Sysmon to install itself and load the config file.
	# Old CMD Version: cmd.exe "$global:SysmonExe -accepteula -i -c $global:SysmonConfig"
	# In a new sub-process, run the Sysmon executable with the -accepteula -i -c flags. Wait for the process to complete before continuing.
	Start-Process -FilePath "$global:SysmonExe" -ArgumentList "-accepteula -i $global:SysmonConfig" -Wait -NoNewWindow

	# Check if the Sysmon service is running, if then return true.
	if (Get-SysmonStatus) {
		return $true
	} else {
		return $false
	}
}

Function Stop-SysmonService {
	<#
	.SYNOPSIS
		Stop the Sysmon service.
	.DESCRIPTION
		This function will stop the Sysmon service.
	.EXAMPLE
		PS> Stop-SysmonService
	.OUTPUTS
		[bool] True if the Sysmon service was stopped successfully, false if it was not.
	#>

	# Get the Sysmon service name.
	$SysmonServiceName = (Get-Service | Where-Object {$_.DisplayName -like "*Sysmon*"}).Name
	try {
		# Stop the service if it is running
		if ($(Get-Service -Name $SysmonServiceName -ErrorAction SilentlyContinue).Status -eq 'Running') {
			Stop-Service -Name $SysmonServiceName -Force
			# Wait for the service to stop, up to 15 seconds
			(Get-Service -Name $SysmonServiceName).WaitForStatus('Stopped','00:00:15')
		}
		# Check if the service is stopped
		if ($(Get-Service -Name $SysmonServiceName -ErrorAction SilentlyContinue).Status -ne 'Running') {
			return $true
		} else {
			return $false
		}
	} catch {
		# If here, the service is not running
		return $true
	}
}

Function Start-SysmonService {
	<#
	.SYNOPSIS
		Stop the Sysmon service.
	.DESCRIPTION
		This function will stop the Sysmon service.
	.EXAMPLE
		PS> Stop-SysmonService
	.OUTPUTS
		[bool] True if the Sysmon service was stopped successfully, false if it was not.
	#>

	# Get the Sysmon service name.
	$SysmonServiceName = (Get-Service | Where-Object {$_.DisplayName -like "*Sysmon*"}).Name

	# If $SysmonServiceName is null or empty, return false.
	if ([string]::IsNullOrEmpty($SysmonServiceName)) {
		if ($global:debug) {Write-Host "The Sysmon service test came back null or empty. AKA: Service not found. Sysmon service needs to be installed."  -ForegroundColor Yellow}
		return $false
	}

	try {
		# Start the service if it is NOT running
		if ($(Get-Service -Name $SysmonServiceName -ErrorAction SilentlyContinue).Status -ne 'Running') {
			# Start the service
			Start-Service -Name $SysmonServiceName
			# Wait for the service to start, up to 15 seconds
			(Get-Service -Name $SysmonServiceName).WaitForStatus('Running','00:00:15')
		}
		# Check if the service is runnig
		if ($(Get-Service -Name $SysmonServiceName -ErrorAction SilentlyContinue).Status -eq 'Running') {
			return $true
		} else {
			return $false
		}
	} catch {
		# If here, the service is not running
		return $false
	}
}

Function Remove-Sysmon {
	<#
	.SYNOPSIS
		Remove the Sysmon.
	.DESCRIPTION
		This function will remove the Sysmon.
	.EXAMPLE
		PS> Remove-Sysmon
	.OUTPUTS
		[bool] True if the Sysmon was removed successfully, false if it was not.
	#>

	# Set default return value.
	[bool]$SysmonRemoved = $false

	# Check if the sysmon service is running, if so stop it.
	if (Get-SysmonStatus) {
		Stop-SysmonService
	}

	# Confirm the Sysmon service is stopped.
	if (Get-SysmonStatus) {
		throw "Error stopping Sysmon service."
		Exit 1
	}

	# Uninstall the Sysmon service
	if (Test-Path $global:SysmonExe) {
		Start-Process $global:SysmonExe -ArgumentList "-u force" -Wait -NoNewWindow
	} else {
		throw "Sysmon executable not found at $global:SysmonExe. Remove-Sysmon failed."
	}

	# Remove the Sysmon executable.
	Remove-Item $global:SysmonExe -Force -ErrorAction SilentlyContinue

	# Confirm the Sysmon executable was removed.
	if (Test-Path $global:SysmonExe) {
		throw "Error removing Sysmon executable."
		Exit 1
	} Elseif (!(Test-Path $global:SysmonExe)) {
		# The Sysmon executable was removed. Return true.
		$SysmonRemoved = $true
	}

	return $SysmonRemoved
}

Function Initialize-DeploySysmon {
	<#
	.SYNOPSIS
		Main function of the Sysmon deployment script.
	.DESCRIPTION
		Check if Sysmon is installed, the latest version, and is it running. If it is not installed, install it. If it is not the latest version, update it. If it is not running, start it.
	.EXAMPLE
		PS> Initialize-DeploySysmon
	.OUTPUTS
		[bool] True if the Sysmon was installed successfully, false if it was not.
	#>

	# Check if the Sysmon service is running, if it is not, Check if the Sysmon is installed, if it is not, install it.
	if (!(Get-SysmonStatus)) {

		# Sysmon is not running, check if it is installed.
		if (!(Test-Path $global:SysmonExe)) {

			# If debug is enabled, write output to the console.
			if ($global:debug) {Write-Host "Sysmon is not installed, installing Sysmon. TestPath: $global:SysmonExe" -ForegroundColor Yellow}

			# Sysmon is not installed, install it.
			# Try to run the Sysmon installer and throw an error if it returns false.
			if (!(Install-Sysmon)) {
				throw "Error installing Sysmon."
				Exit 1
			}
		}

		if (Test-Path $global:SysmonExe) {

			if ($global:debug) {Write-Host "Sysmon IS found. TestPath: $global:SysmonExe" -ForegroundColor Yellow }

			# Sysmon is installed, Check if the Sysmon is the latest version, if it is not, update it.
			[bool]$SysmonUpdateRequired = Get-SysmonUpdateRequired # Adding as a variable to reduce the number of web requests.

			# Check if the Sysmon is the latest version, if it is not, update it.
			if ($SysmonUpdateRequired) {
				if ($global:debug) {Write-Host "A Sysmon Update is required." -ForegroundColor Yellow }
				# Remove the Sysmon.
				# Try to run the Sysmon removal and throw an error if it returns false.
				if (!(Remove-Sysmon)) {
					throw "Error removing Sysmon."
					Exit 1
				}
				# An update is required, update it.
				# Try to run the Sysmon installer and throw an error if it returns false.
				if (!(Install-Sysmon)) {
					throw "Error installing Sysmon."
					Exit 1
				}
			}

			# Sysmon is the latest version, start it.
			# Try to run the Sysmon installer and throw an error if it returns false.
			if (!(Start-SysmonService)) {
				if ($global:debug) {Write-Host "Failed to start Sysmon service, trying reinstall." -ForegroundColor Yellow }

				if (!(Install-Sysmon)) {
					throw "Error installing Sysmon."
					Exit 1
				}

				if (!(Start-SysmonService)) {
					throw "Error reinstalling Sysmon and starting the service failed."
					Exit 1
				}
			}
			# Sysmon is running, & latest version, return true.
			return $true
		}
	}

	# IF the Sysmon service is running, check if the Sysmon is the latest version, if it is not, update it.
	if (Get-SysmonStatus) {
		if (Get-SysmonUpdateRequired) {

			# Try to run the stop Sysmon service and throw an error if it returns false.
			if (!(Stop-SysmonService)) {
				throw "Error stopping Sysmon service."
				Exit 1
			}

			# Try to run the Sysmon removal and throw an error if it returns false.
			if (!(Remove-Sysmon)) {
				throw "Error removing Sysmon."
				Exit 1
			}

			# Try to run the Sysmon installer and throw an error if it returns false.
			if (!(Install-Sysmon)) {
				throw "Error installing Sysmon."
				Exit 1
			}

			# Sysmon is the latest version, start it.
			# Try to run the Sysmon installer and throw an error if it returns false.
			if (!(Start-SysmonService)) {
				throw "Error starting Sysmon service."
				Exit 1
			}
		}
		# Sysmon is running, & latest version, return true.
		return $true
	}
}

# Try to create the event log, if it already exists, do nothing.
try {
	(New-EventLog -LogName Application -Source "SysmonDeploy" -ErrorAction SilentlyContinue) | Out-Null
}
catch {
	# Do nothing. The event log already exists.
}
# Run the Initialize-DeploySysmon function and write the result to the event log.
Write-EventLog -LogName Application -Source "SysmonGpoDeploy" -EntryType Information -EventId 1 -Message $(Initialize-DeploySysmon) -ErrorAction SilentlyContinue
# Exit with error code 0.
Exit 0