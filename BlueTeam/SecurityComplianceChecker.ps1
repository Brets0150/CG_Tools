# A fuction that checks the currect version of PowerShell this script is running on and return the version number.
#
# @return [String] The version number of the current PowerShell session.
function Get-PowerShellVersion {
    return $PSVersionTable.PSVersion.ToString()
}

# A fuction that checks the currect version of PowerShell is less than 5.1 and if it is, it will upgrade the version.
#
# @return [String] The version number of the current PowerShell session.
function Update-PowerShell {

    <#
    .DESCRIPTION
        This function will check the current version of PowerShell and if it is less than 5.1, it will downlaod the correct msu package based on the OS and install it.
    #>

    try {
        if ($PSVersionTable.PSVersion.Major -lt 5 -or ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -lt 1)) {
            # Check is the OS is Server 2012R2 or greater. If it is, download the correct msu package.
            if ((Get-CimInstance -ClassName Win32_OperatingSystem).Version -ge 6.3) {
                $url = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win8.1AndW2K12R2-KB3191564-x64.msu"
            } else {
                Write-Host "This script requires the OS to be Windows Server 2012 R2 or greater. Exiting..."
                throw "OS Version not supported"
            }
        }
    }
    catch {
        Write-host "Encountered Error:"$_.Exception.Message -ForegroundColor red
    }

    return $PSVersionTable.PSVersion.ToString()
}
