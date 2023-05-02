#Requires -RunAsAdministrator
<#
.SYNOPSIS

.VERSION
    1.0.0

.DESCRIPTION
    A tool to export Windows Event Logs to a zip file. The zip file will be named "EventLogExports.zip" and will be saved to a location of the users choosing.

.EXAMPLE
    PS C:\> .\WindowsIrLogExport.ps1
.LINK
    https://github.com/Brets0150/CG_Tools/tree/main/WindowsAdmin/WindowsIrLogExport.ps1
.NOTES
    Author: Bret.s AKA: CyberGladius / License: MIT
#>

#
# A list variable with the most common logs to export.
[array]$global:commonlogList = @("Application", "Security", "System", "Microsoft-Windows-AppLocker/EXE and DLL", "Microsoft-Windows-Windows Defender/Operational",
                            "Microsoft-Windows-Sysmon/Operational", "Windows PowerShell", "Microsoft-Windows-PowerShell/Operational", "Microsoft-Windows-DNS-Client/Operational",
                            "Microsoft-Windows-TaskScheduler/Operational", "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational", "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational",
                            "Microsoft-Windows-TerminalServices-RDPClient/Operational", "Microsoft-Windows-Windows Firewall With Advanced Security/Firewall")

# A string variable with the file name of the hash file.
[string]$global:hashFileName = "EventLogExportsFileHashes.txt"

# A string variable with the defautl Windows Event Log directory path.
[string]$global:logDirectoryPath = "$env:SystemRoot\System32\Winevt\Logs"

# A function to confirm this script can access the "wevtutil.exe" utility. If not, it will return $false, an error message in red, and exit the script.
function Confirm-Wevtutil {
    $wevtutil = Get-Command wevtutil -ErrorAction SilentlyContinue
    if ($null -eq $wevtutil) {
        Write-Host "The wevtutil.exe utility is not available. Please run this script from an elevated PowerShell prompt." -ForegroundColor Red
        return $false
        # exit script
        exit 1
    }
}

# A function that remove any characters that are not allowed in a file names or file paths.
Function Remove-InvalidFileNameChars {
    param(
      [Parameter(Mandatory=$true,
        Position=0,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
      [String]$Name
    )
    $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
    $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
    return ($Name -replace $re)
}

# A function to take in a full path to a file, get the MD5 hash of the file, then append a given text file with "$File;$FileHash".
function Write-FileHash {
    param (
        [Parameter(Mandatory=$true)]
        [string]$File,
        [Parameter(Mandatory=$true)]
        [string]$HashFile
    )
    # Get the MD5 hash of the file.
    $FileHash = Get-FileHash -Path $File -Algorithm MD5 | Select-Object -ExpandProperty Hash
    # Append the hash file with the file name and hash.
    Add-Content -Path $HashFile -Value "$File;$FileHash"
}

# A function that use "wevtutil.exe" to build a list of all logs enabled on the system and then returns the list.
function Get-LogList {
    Write-Host "Building list of logs to export. This may take a minute..." -ForegroundColor Green
    [array]$logList = wevtutil el
    $logList = Remove-DisabledLogs -logList $logList
    return $logList
}

# Function to filter the list of logs and removes any logs that are not enabled on the system.
function Remove-DisabledLogs {
    param (
        [Parameter(Mandatory=$true)]
        [array]$logList
    )
    # for each log in the list, run the "wevtutil gl" command and check if the log is enabled. If the log is not enabled, remove it from the list.
    foreach ($log in $logList) {
        $logStatus = wevtutil gl "$log" | Select-String "enabled: false"
        # Remove carriage return and line feed characters from $logStatus.
        $logStatus = $logStatus -replace "`r`n"
        # Test if $logStatus is null or empty. If not, remove $log from $logList.
        if ($logStatus) {
            $logList = $logList -ne $log
        }
    }
    return $logList
}

# A function that will take a directory path of a folder to be zipped up and the name of the zip file to create. The function will then create the zip file. Ask the user where to save the zip file.
function New-ZipFile {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DirectoryPath,
        [Parameter(Mandatory=$true)]
        [string]$ZipFileName
    )
    # Check if the directory exists. If not, exit the script.
    if (-not (Test-Path $DirectoryPath)) {
        Write-Host "The directory $DirectoryPath does not exist. Exiting script." -ForegroundColor Red
        exit 1
    }

    # Tell the user they will be asked where to save the zip file, and it cannot be saved in the directory being zipped up.
    Write-Host "You will be asked where to save the zip file. It cannot be saved in the directory being zipped up." -ForegroundColor Yellow

    # While loop to ask the user where to save the zip file. If the user enters a directory that is the same as the directory being zipped up, ask the user to enter a different directory.
    #  If the user enters a directory that does not exist, ask the user to enter a different directory.
    while ($true) {
        # Ask the user where to save the zip file.
        [string]$ZipSaveDirectory = Get-ExportDirectory
        # Check if the directory entered is the same as the directory being zipped up. If it is, ask the user to enter a different directory.
        if ($ZipSaveDirectory -eq $DirectoryPath) {
            Write-Host "The zip file cannot be saved in the directory being zipped up. Please enter a different directory." -ForegroundColor Red
        }
        elseif (-not (Test-Path $ZipSaveDirectory)) {
            Write-Host "The directory $ZipSaveDirectory does not exist. Please enter a different directory." -ForegroundColor Red
        }
        else {
            break
        }
    }

    # Set zip file complete path and name in one string variable.
    [string]$ZipFileCompleteName = "$ZipSaveDirectory\$ZipFileName"

    # Check if the zip file already exists. If it does, ask the user if they want to overwrite it. If not, exit the script.
    if (Test-Path $ZipFileCompleteName) {
        [string]$Overwrite = Read-Host "The file $ZipFileCompleteName already exists. Do you want to overwrite it? (Y/N)"
        if ($Overwrite -eq "N") {
            Write-Host "Exiting script." -ForegroundColor Red
            exit 1
        }
    }
    # Create a new zip file.
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($DirectoryPath, $ZipFileCompleteName)
    # Get the zip file disk size in MB rounded up to one decimal place, then tell the user the zip file was created and the size of the zip file.
    [double]$ZipFileSize = (Get-Item $ZipFileCompleteName).length / 1MB
    $ZipFileSize = [math]::Round($ZipFileSize, 1)
    Write-Host "The zip file $ZipFileCompleteName was created. The size of the zip file is $ZipFileSize MB." -ForegroundColor Green
    return
}

# A fuction that will take directory path name and a zip file name as a string, then ask the user if they wish to zip up the directory. If so, it will call the New-ZipFile function.
function Get-ZipFileDirectory {
    param (
        [Parameter(Mandatory=$true)]
        [string]$DirectoryPath,
        [Parameter(Mandatory=$true)]
        [string]$ZipFileName
    )
    # A while loop to ask the user if they want to zip up the directory. If the user enters an invalid response, ask the user to enter a valid response.
    while ($true) {
        [string]$ZipDirectory = Read-Host "Do you want to zip up the directory $DirectoryPath? (Y/N)"
        if ($ZipDirectory -eq "Y") {
            New-ZipFile -DirectoryPath $DirectoryPath -ZipFileName $ZipFileName
            break
        }
        elseif ($ZipDirectory -eq "N") {
            break
        }
        else {
            Write-Host "Please enter a valid response." -ForegroundColor Red
        }
    }
    return
}

# A function that will open a popup folder browser dialog box and return the path selected by the user.
function Get-ExportDirectory {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $FolderBrowser.Description = "Select the directory to export the logs to"
    $FolderBrowser.ShowDialog() | Out-Null
    $ExportDirectory = $FolderBrowser.SelectedPath
    # Check if the user selected a directory and the directory already exists. If not, exit the script.
    if (Test-Path $ExportDirectory) {
        return $ExportDirectory
    }
    Write-Host "No directory was selected. Exiting script." -ForegroundColor Red
    exit 1
}

# A function that will check how much disc space is being used by all the logs on the system.
function Find-LogSize {
    $TotalSize = (Get-ChildItem $global:logDirectoryPath -Recurse | Measure-Object -Property Length -Sum).Sum
    # Convert $TotalSize to MB and round to two decimal places.
    $TotalSizeMB = [math]::Round(($TotalSize / 1MB),2)
    $TotalSizeGB = [math]::Round(($TotalSize / 1GB),2)
    Write-Host "The total size of all the logs is $TotalSizeGB GB($TotalSizeMB MB)." -ForegroundColor Green
    # Check how much free space is available on the C: drive.
    $FreeSpace = (Get-PSDrive C).Free
    # Convert $FreeSpace to MB and round to two decimal places.
    $FreeSpaceMB = [math]::Round(($FreeSpace / 1MB),2)
    $FreeSpaceGB = [math]::Round(($FreeSpace / 1GB),2)
    Write-Host "There is $FreeSpaceGB GB($FreeSpaceMB MB) of free space on the C: drive." -ForegroundColor Green
    # If the total size of the logs is greater than the free space on the C: drive, tell the user, but do not exit.
    if ($TotalSize -gt $FreeSpace) {
        Write-Host "The total size of the logs is greater than the free space on the C: drive." -ForegroundColor Red
        Write-Host "Export logs to another disk, or network location." -ForegroundColor Red
    }
    return
}

# A function that uses "wevtutil.exe" to export the contents of a log to a file. The function takes two parameters: the name of the log to export and the name of the directory to export the logs to. Test the directory to make sure it exists.
# If it does not, create it. Then export the log to the directory.
function Export-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogName,
        [Parameter(Mandatory=$true)]
        [string]$ExportDirectory
    )
    if (-not (Test-Path $ExportDirectory)) {
        [string]$CreateDirectory = Read-Host "The directory $ExportDirectory does not exist. Do you want to create it? (Y/N)"
        if ($CreateDirectory -eq "Y" -or $CreateDirectory -eq "y") {
            New-Item -Path $ExportDirectory -ItemType Directory
            # If the directory is created, tell the user. If not, tell the user and exit the script.
            if (Test-Path $ExportDirectory) {
                Write-Host "The directory $ExportDirectory was created." -ForegroundColor Green
            }
            else {
                Write-Host "The directory $ExportDirectory was not created. Exiting script." -ForegroundColor Red
                exit
            }
        }
    }
    if (Test-Path $ExportDirectory) {
        # Remove any characters that are not allowed in a file name.
        $FileLogName = Remove-InvalidFileNameChars -Name $LogName
        # Get todays Date and time.
        $Date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        # Get this computer's name.
        $ComputerName = "$env:COMPUTERNAME"
        $ExportedFileLogName = "$FileLogName---$ComputerName-$Date.evtx"
        # Export the log to the directory.
        wevtutil epl "$LogName" "$ExportDirectory\$ExportedFileLogName"
        Write-FileHash -File "$ExportDirectory\$ExportedFileLogName" -HashFile "$ExportDirectory\$global:hashFileName"
    }
    return
}

# A function than asks the if they want to export all the logs or just a specific log. If they want to export all the logs, call the Get-LogList function to get a list of all the logs.
# Ask the user for the directory to export the logs to. Then call the Export-Log function for each log in the list.
function Export-AllLogs {
    $logList = Get-LogList
    $ExportDirectory = Get-ExportDirectory
    foreach ($log in $logList) {
        Export-Log -LogName "$log" -ExportDirectory "$ExportDirectory"
        # After the single log export completes, tell the user the export is complete.
        Write-Host "Export of $log complete" -ForegroundColor Green
    }
    # Tell the user all logs have been exported.
    Write-Host "All logs have been exported." -ForegroundColor Green
    # Get todays Date and time.
    $Date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    # Get this computer's name.
    $ComputerName = "$env:COMPUTERNAME"
    #  Ask the user if they want to zip up the directory.
    Get-ZipFileDirectory -DirectoryPath $ExportDirectory -ZipFileName "All-Event-Logs--$ComputerName-$Date.zip"
    return
}

# A function to export the most common logs needed for incident response.
function Export-CommonLogs {
    # Tell the user the logs that will be exported.
    Write-Host "The following logs will be exported if they are enabled." -ForegroundColor Green
    foreach ($log in $global:commonlogList) {
        Write-Host " --> $log" -ForegroundColor Green
    }
    $ExportDirectory = Get-ExportDirectory
    # Filter the "$global:commonlogList" for logs that are disabled.
    [array]$LogList = Remove-DisabledLogs -logList $global:commonlogList
    # Export the logs to the directory.
    foreach ($log in $LogList) {
        Export-Log -LogName $log -ExportDirectory $ExportDirectory
        # After the single log export completes, tell the user the export is complete.
        Write-Host "Export of $log complete" -ForegroundColor Green
    }
    # Tell the user all logs have been exported.
    Write-Host "All logs have been exported." -ForegroundColor Green
    # Get todays Date and time.
    $Date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    # Get this computer's name.
    $ComputerName = "$env:COMPUTERNAME"
    #  Ask the user if they want to zip up the directory.
    Get-ZipFileDirectory -DirectoryPath $ExportDirectory -ZipFileName "Common-Event-Logs--$ComputerName-$Date.zip"
    return
}

# A function that exports one specific log file that the user chooses.
function Export-SpecificLog {
    # Create a dictonary with a unique number for each log name discovered with Get-LogList.
    $logList = Get-LogList
    $logListDict = @{}
    $i = 1
    foreach ($log in $logList) {
        $logListDict.Add($i,$log)
        $i++
    }
    # Use the $loglistDict to create a list of log names and numbers for the user to choose from.
    Write-Host "The following logs are available to export" -ForegroundColor Yellow
    foreach ($key in $logListDict.Keys) {
        Write-Host "$key. $($logListDict[$key])" -ForegroundColor Green
    }
    # Ask the user to choose a log to export.
    [int]$logNumber = Read-Host "Enter the number of the log to export"
    # If the user enters a number that is not in the list, tell the and restart the function.
    if ($logNumber -gt $logListDict.Count) {
        Write-Host "The number you entered is not in the list. Please try again." -ForegroundColor Red
        Export-SpecificLog
    }
    # Repeat back to the user the log they chose.
    Write-Host "You chose $($logListDict[$logNumber])" -ForegroundColor Green
    # Tell the they will need to choose a directory to export the log to.
    Write-Host "You will now be asked to choose a directory to export the log to." -ForegroundColor Yellow
    $ExportDirectory = Get-ExportDirectory
    # Repeat back to the user the directory they chose.
    Write-Host "You chose $ExportDirectory" -ForegroundColor Green
    # Export the log to the directory.
    Export-Log -LogName $($logListDict[$logNumber]) -ExportDirectory $ExportDirectory
    # Tell the user all logs have been exported.
    Write-Host "All logs have been exported." -ForegroundColor Green
    # Get todays Date and time.
    $Date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    # Get this computer's name.
    $ComputerName = "$env:COMPUTERNAME"
    #  Ask the user if they want to zip up the directory.
    Get-ZipFileDirectory -DirectoryPath $ExportDirectory -ZipFileName "All-Event-Logs--$ComputerName-$Date.zip"
    return
}

# A fucntion that builds a main menu for the user to select from.
function Start-MainMenu {
    Write-Host "=====================" -ForegroundColor Black
    Confirm-Wevtutil
    Find-LogSize
    Write-Host "=====================" -ForegroundColor Black
    Write-Host "1. Export ALL Windows Event Logs" -ForegroundColor Green
    Write-Host "2. Export the most common Windows Event Logs" -ForegroundColor Green
    Write-Host "3. Export one specific Windows Event Logs" -ForegroundColor Green
    Write-Host "4. Exit" -ForegroundColor Green
    Write-Host "=====================" -ForegroundColor Black
    $menuChoice = Read-Host "Enter the number of the option you want to select"
    switch ($menuChoice) {
        1 {Export-AllLogs}
        2 {Export-CommonLogs}
        3 {Export-SpecificLog}
        4 {exit}
        default {Write-Host "You did not enter a valid option. Please try again." -ForegroundColor Red; MainMenu}
    }
}

# Main script
Start-MainMenu