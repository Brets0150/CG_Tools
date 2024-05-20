#Defining important functions
Function Enable-WinRM {
    <#
    .DESCRIPTION
        This function will start the Kape collection process. THis process includes...
        1. Mapping a network drive where KAPE will store the collected data and the ISO file containing the KAPE tool.
        2. Mounting the KAPE ISO file.
        3. Creating a directory for the collected data.

    .PARAMETER ShareServerIP
        The IP address of the server hosting the network share.

    .PARAMETER ShareName
        The name of the network share.

    .PARAMETER KapeIsoFileName
        The name of the KAPE ISO file.

    .EXAMPLE
        PS C:\> Initiate-KapeCollect -ShareServerIP "10.10.10.10" -ShareName "Share" -KapeIsoFileName "kape.iso"
    #>
    Param(
        [Parameter(Mandatory=$False,Position=2)][string]$SmbShare,
        [Parameter(Mandatory=$True,Position=4)][string]$KapeIsoFileName,
        [Parameter(Mandatory=$True,Position=1)][pscredential]$SmbCredential
    )
    $SessionArgs = @{
      ComputerName  = $target
      Credential    = $Cred
      SessionOption = New-CimSessionOption -Protocol Dcom
  }
  $MethodArgs = @{
      ClassName     = 'Win32_Process'
      MethodName    = 'Create'
      CimSession    = New-CimSession @SessionArgs
      Arguments     = @{
          CommandLine = "powershell Start-Process powershell -ArgumentList 'Enable-PSRemoting -Force'"
      }
  }
  Invoke-CimMethod @MethodArgs
}

function Connect-KapeCollectResources {
    <#
    .DESCRIPTION
        This function will start the Kape collection process. THis process includes...
        1. Mapping a network drive where KAPE will store the collected data and the ISO file containing the KAPE tool.
        2. Mounting the KAPE ISO file.
        3. Creating a directory for the collected data.

    .PARAMETER ShareServerIP
        The IP address of the server hosting the network share.

    .PARAMETER ShareName
        The name of the network share.

    .PARAMETER KapeIsoFileName
        The name of the KAPE ISO file.

    .EXAMPLE
        PS C:\> Initiate-KapeCollect -ShareServerIP "10.10.10.10" -ShareName "Share" -KapeIsoFileName "kape.iso"
    #>
    Param(
        [Parameter(Mandatory=$False,Position=2)][string]$SmbShare,
        [Parameter(Mandatory=$True,Position=4)][string]$KapeIsoFileName,
        [Parameter(Mandatory=$True,Position=1)][pscredential]$SmbCredential
    )

    # Extract the server IP and share name from the network share path.
    $ShareServerIP = $SmbShare.Split("\")[2]

    # Test if this system can connect to the network share IP and folder.
    if (-not (Test-Connection -ComputerName $ShareServerIP -Count 1 -Quiet)) {
        Write-Host "Unable to connect to the network share at $ShareServerIP. Exiting..."
        return
    }

    # Test if we can connect to the network share with the provided credentials.
    if (-not (Test-Path "$SmbShare" -Credential $SmbCredential)) {
        Write-Host "Unable to connect to the network share at `"$SmbShare`" with the provided credentials. Exiting..."
        return
    }

    # Test if the KAPE ISO file exists on the network share.
    if (-not (Test-Path "$SmbShare\$KapeIsoFileName" -Credential $ShareCredential)) {
        Write-Host "Unable to find the KAPE ISO file at `"$SmbShare\$KapeIsoPath`". Exiting..."
        return
    }

    # Get the next available drive letter and append a colon to it.
    $NetShareDriveLetter = "$([char](67..90 | Where-Object { -not (Get-Volume -DriveLetter $_ -ErrorAction SilentlyContinue) } | Select-Object -First 1)):"

    # Map the network share to the next available drive letter.
    # New-SmbMapping -LocalPath "$NetShareDriveLetter" -RemotePath "$SmbShare" -UserName $ShareCredential.UserName -Password $ShareCredential.GetNetworkCredential().Password
    New-PSDrive -Name "$NetShareDriveLetter" -Persist -PSProvider "FileSystem" -Root "$SmbShare" -Credential $SmbCredential

    # Mount the KAPE ISO file.
    Mount-DiskImage -ImagePath "$NetShareDriveLetter\$KapeIsoFileName"

    # Get the drive letter of the mounted ISO file.
    $KapeIsoMountLetter = (Get-Volume | Where-Object { $_.FileSystemLabel -eq "$($KapeIsoFileName)" }).DriveLetter + ":"

    # Create a directory for the collected data.
    New-Item -Path "$NetShareDriveLetter\Collections\$env:computername" -ItemType Directory

    Return $NetShareDriveLetter, $KapeIsoMountLetter
}

Function Disconnect-KapeCollectResources {
    <#
    .DESCRIPTION
        This function will disconnect the network share and unmount the KAPE ISO file.

    .PARAMETER NetShareDriveLetter
        The drive letter of the network share.

    .PARAMETER KapeIsoMountLetter
        The drive letter of the mounted KAPE ISO file.

    .EXAMPLE
        PS C:\> Disconnect-KapeCollectResources -NetShareDriveLetter "E:" -KapeIsoMountLetter "D:"
    #>
    Param(
        [Parameter(Mandatory=$True,Position=1)][string]$NetShareDriveLetter,
        [Parameter(Mandatory=$True,Position=2)][string]$KapeIsoMountLetter
    )

    # Remove the network share mapping.
    Remove-SmbMapping -LocalPath "$NetShareDriveLetter"

    # Unmount the KAPE ISO file.
    Dismount-DiskImage -ImagePath "$KapeIsoMountLetter"
}

function Start-KapeCollect {
    <#
    .DESCRIPTION
        This function will start the Kape collection process. This process includes...
        1. Running the KAPE tool with the specified target directory and output directory.
        2. Unmounting the KAPE ISO file.
        3. Removing the network share mapping.

    .PARAMETER KapeIsoMountLetter
        The drive letter of the mounted KAPE ISO file.

    .PARAMETER NetShareDriveLetter
        The drive letter of the network share.

    .PARAMETER TargetDirectory
        The directory to collect data from.

    .PARAMETER OutputDirectory
        The directory to store the collected data.

    .EXAMPLE
        PS C:\> Start-KapeCollect -KapeIsoMountLetter "D:" -NetShareDriveLetter "E:" -Target "C:" -OutputDirectory "E:\Collections\MyComputer"
    #>
    Param(
        [Parameter(Mandatory=$True,Position=1)][string]$KapeIsoMountLetter,
        [Parameter(Mandatory=$True,Position=2)][string]$NetShareDriveLetter,
        [Parameter(Mandatory=$True,Position=3)][string]$Target,
        [Parameter(Mandatory=$True,Position=4)][string]$OutputDirectory,
        [Parameter(Mandatory=$False,Position=5)][switch]$TargetCollectionScript,
        [Parameter(Mandatory=$False,Position=5)][switch]$TempMemCapture
    )

    try {
        #check if the target directory, output directory, KapeIsoMountLetter, and "$KapeIsoMountLetter\kape.exe" exist and are valid.
        if (-not (Test-Path $Target)) {
            Write-Host "The target directory $Target does not exist. Exiting..."
            throw "Target directory not found"
        }
        if (-not (Test-Path $OutputDirectory)) {
            Write-Host "The output directory $OutputDirectory does not exist. Exiting..."
            throw "Output directory not found"
        }
        if (-not (Test-Path $KapeIsoMountLetter)) {
            Write-Host "The Kape ISO mount letter $KapeIsoMountLetter does not exist. Exiting..."
            throw "Kape ISO mount letter not found"
        }
        if (-not (Test-Path "$KapeIsoMountLetter\kape.exe")) {
            Write-Host "The Kape executable $KapeIsoMountLetter\kape.exe does not exist. Exiting..."
            throw "Kape executable not found"
        }

        # If the TempMemCapture switch is enabled, add the appropriate argument to the KAPE command.
        if ($TempMemCapture) {
            # Check that the winpmem binary is present in the KAPE directory; $KapeIsoMountLetter\KAPE\Modules\bin\winpmem.exe
            if (-not (Test-Path "$KapeIsoMountLetter\KAPE\Modules\bin\winpmem.exe")) {
                Write-Host "Unable to find the winpmem binary in the KAPE ISO file. Exiting..."
                throw "winpmem binary not found"
            }
            # K:\KAPE\kape.exe --msource C:\ --mdest I:\Collections\"$($env:computername)" --mflush --zm true --module Velocidex_WinPmem
            Start-Process -FilePath "$KapeIsoMountLetter\kape.exe" -ArgumentList "--msource $Target --mdest $OutputDirectory --zm true --module Velocidex_WinPmem" -Wait

            # Check if the memory capture was successful; confirm the file "$OutputDirectory\*_ModulesOutput.zip" exists.
            if (-not (Test-Path "$OutputDirectory\*_ModulesOutput.zip")) {
                Write-Host "Memory capture failed. Exiting..."
                throw "Memory capture failed"
            }
        }
        # Start KAPE data collection.
        # K:\KAPE\kape.exe --tsource C: --tdest I:\Collections\WINTERFELL --target !SANS_Triage --zip "$($env:computername)"
        Start-Process -FilePath "$KapeIsoMountLetter\kape.exe" -ArgumentList "--tsource $Target --tdest $OutputDirectory --target $TargetCollectionScript --zip $($env:computername)" -Wait

        # Check if the data collection was successful; confirm the file "$OutputDirectory\*_$($env:computername).zip" exists.
        if (-not (Test-Path "$OutputDirectory\*_$($env:computername).zip")) {
            Write-Host "Data collection failed. Exiting..."
            throw "Data collection failed"
        }
    }
    catch {
        Write-host "Encountered Error:"$_.Exception.Message -ForegroundColor red
    }
    finally {
        # Unmount the KAPE ISO file.
        Dismount-DiskImage -ImagePath "$KapeIsoMountLetter"

        # Remove the network share mapping.
        Remove-SmbMapping -LocalPath "$NetShareDriveLetter"
   }
}

function Invoke-KapeCollect {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True,Position=1)][string]$SmbShare,
        [Parameter(Mandatory=$True,Position=2)][pscredential]$SmbCredential,
        [Parameter(Mandatory=$false,Position=3)][string]$KapeIsoFileName,
        [Parameter(Mandatory=$false,Position=4)][string]$Target,
        [Parameter(Mandatory=$false,Position=5)][string]$TargetCollectionScript,
        [Parameter(Mandatory=$false,Position=6)][switch]$TempMemCapture
    )

    begin {
        # Set up the default values for the parameters.
        ##
        # If $SmbCredential is not provided, prompt the user for the credentials to access the network share.
        if (-not $SmbCredential) {
            # Prompt the user for the credentials to access the network share.
            $SmbCredential = Get-Credential -Message "Enter the credentials to access the network share at $SmbShare"
        }
        # If $target is not provided, set the target to the root of the C: drive.
        if (-not $Target) {
            $Target = "C:\"
        }
        # If $KapeIsoFileName is not provided, set the KAPE ISO file name to "kape.iso".
        if (-not $KapeIsoFileName) {
            $KapeIsoFileName = "kape.iso"
        }
        # If $TargetCollectionScript is not provided, set the target collection script to "!SANS_Triage".
        if (-not $TargetCollectionScript) {
            $TargetCollectionScript = "!SANS_Triage"
        }
        # If $TempMemCapture is not provided, set the TempMemCapture switch to $True.
        if (-not $TempMemCapture) {
            $TempMemCapture = $True
        }
    }

    process {

        try {
            # Connect to the network share and mount the KAPE ISO file.
            $NetShareDriveLetter, $KapeIsoMountLetter = Connect-KapeCollectResources -SmbShare $SmbShare -KapeIsoFileName $KapeIsoFileName -SmbCredential $SmbCredential
            # Start the KAPE collection process.
            Start-KapeCollect -KapeIsoMountLetter $KapeIsoMountLetter -NetShareDriveLetter $NetShareDriveLetter -Target $Target
        }
        catch {
            Write-host "Encountered Error:"$_.Exception.Message -ForegroundColor red
        }
        finally {
            # Disconnect from the network share and unmount the KAPE ISO file.
            Disconnect-KapeCollectResources -NetShareDriveLetter $NetShareDriveLetter -KapeIsoMountLetter $KapeIsoMountLetter
        }

    }

    end {
        # Clean up the variables.
        Remove-Variable -Name NetShareDriveLetter, KapeIsoMountLetter
    }
}

function Invoke-KapeRemoteCollect {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True, Position=1)][string]$SmbShare,
        [Parameter(Mandatory=$True, Position=2)][string]$RemoteComputerName,
        [Parameter(Mandatory=$False,Position=3)][pscredential]$SmbCredential,
        [Parameter(Mandatory=$False,Position=4)][pscredential]$RemoteComputerCredential,
        [Parameter(Mandatory=$False,Position=5)][string]$KapeIsoFileName,
        [Parameter(Mandatory=$False,Position=6)][string]$Target,
        [Parameter(Mandatory=$False,Position=7)][string]$TargetCollectionScript,
        [Parameter(Mandatory=$False,Position=8)][switch]$TempMemCapture
    )

    begin {
        # Set up the default values for the parameters.
        ##
        # If $RemoteComputerCredential is not provided, prompt the user for the credentials to access the remote computer.
        if (-not $RemoteComputerCredential) {
            # Prompt the user for the credentials to access the remote computer.
            $RemoteComputerCredential = $(Get-Credential -Message "Credentials for remote computer at $RemoteComputerName" -UserName $("$RemoteComputerName\") )
        }
        # Extract the server IP or name from the network share path.
        $SmbAddress = $SmbShare.Split("\")[2]
        $SmbAddress
        # If $SmbCredential is not provided, prompt the user for the credentials to access the network share.
        if (-not $SmbCredential) {
            # Prompt the user for the credentials to access the network share.
            $SmbCredential = $(Get-Credential -Message "Credentials for network share at $SmbShare" -UserName $("$SmbAddress\") )
        }
        # If $target is not provided, set the target to the root of the C: drive.
        if (-not $Target) {
            $Target = "C:\"
        }
        # If $KapeIsoFileName is not provided, set the KAPE ISO file name to "kape.iso".
        if (-not $KapeIsoFileName) {
            $KapeIsoFileName = "kape.iso"
        }
        # If $TargetCollectionScript is not provided, set the target collection script to "!SANS_Triage".
        if (-not $TargetCollectionScript) {
            $TargetCollectionScript = "!SANS_Triage"
        }
        # If $TempMemCapture is not provided, set the TempMemCapture switch to $True.
        if (-not $TempMemCapture) {
            $TempMemCapture = $True
        }

        # Test if this system can connect to the SmbShare IP and folder.
        if (-not (Test-Connection -ComputerName $SmbAddress -Count 1 -Quiet)) {
            Write-Host "Unable to connect to the network share at $SmbAddress. Exiting..."
            return
        }
        # Mount the Smbshare.
        New-PSDrive -Name "KapeCollection" -Persist -PSProvider "FileSystem" -Root "$SmbShare" -Credential $SmbCredential
        #Copy this scrip to the smb share.
        Copy-Item -Path $MyInvocation.MyCommand.Path -Destination "$SmbShare\" -Credential $SmbCredential
        # Set this scripts name to a variable.
        $ScriptName = $($MyInvocation.MyCommand.path.Split("\")[-1])
        # Check if the script was copied successfully.
        if (-not (Test-Path "$SmbShare\$ScriptName" -Credential $SmbCredential)) {
            Write-Host "Unable to copy the script to the network share. Exiting..."
            return
        }
    }

    process {
            try {
                # Output the name of the remote computer.
                Write-Output "Collecting data from $RemoteComputerName"
                # Open a remote PowerShell session to the target computer.
                $RemoteSession = New-PSSession -ComputerName $RemoteComputerName -Credential $RemoteComputerCredential
                # Get the contents of this sctipt and put it in a variable.
                # $ScriptBlock = Get-Content -Path $MyInvocation.MyCommand.Path -Raw
                # Invoke the Kape collection process on the remote computer.
                Invoke-Command -Session $RemoteSession -ScriptBlock {
                    param([string]$SmbShare, [pscredential]$SmbCredential, [string]$KapeIsoFileName, [string]$Target, [string]$TargetCollectionScript, [switch]$TempMemCapture, [string]$ScriptName)
                    Import-Module "$SmbShare\$ScriptName"
                    Invoke-KapeCollect -SmbShare $SmbShare -SmbCredential $SmbCredential -KapeIsoFileName $KapeIsoFileName -Target $Target -TargetCollectionScript $TargetCollectionScript -TempMemCapture
                }
            }
            catch {
                Write-host "`"$RemoteComputerName`" Encountered Error:"$_.Exception.Message -ForegroundColor red
            }
            finally {
                # Close the remote PowerShell session.
                Remove-PSSession -Session $RemoteSession
            }
        }
}
