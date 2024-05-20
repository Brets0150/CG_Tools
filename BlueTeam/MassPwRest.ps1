#Requires -RunAsAdministrator
<#
.SYNOPSIS

.VERSION
    1.0.0

.DESCRIPTION
    This script will attempt to reset the password for all users in the domain. This is useful for a post breach scenario where the attacker has dumped the password hashes and is attempting to crack them.
    This script will reset all the passwords to a random 16 character password, then export the list of users and their new passwords to a CSV file.

.EXAMPLE
    PS C:\> .\MassPwRest.ps1
.LINK
    https://github.com/Brets0150/CG_Tools/
.NOTES
    Author: Bret.s AKA: CyberGladius / License: MIT
#>

# Import the Active Directory module
Import-Module ActiveDirectory;

Function Test-PasswordIsComplex {

    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [String]$StringToTest
    )

	Process {
		$criteriaMet = 0

		# Upper Case Characters (A through Z, with diacritic marks, Greek and Cyrillic characters)
		If ($StringToTest -cmatch '[A-Z]') {$criteriaMet++}

		# Lower Case Characters (a through z, sharp-s, with diacritic marks, Greek and Cyrillic characters)
		If ($StringToTest -cmatch '[a-z]') {$criteriaMet++}

		# Numeric Characters (0 through 9)
		If ($StringToTest -match '\d') {$criteriaMet++}

		# Special Chracters (Non-alphanumeric characters, currency symbols such as the Euro or British Pound are not counted as special characters for this policy setting)
		If ($StringToTest -match '[\^~!@#$%^&*_+=`|\\(){}\[\]:;"''<>,.?/]') {$criteriaMet++}

		# Check If It Matches Default Windows Complexity Requirements
		If ($criteriaMet -lt 3) {Return $false}
		If ($StringToTest.Length -lt 8) {Return $false}
		Return $true
	}
# End of Test-PasswordIsComplex function
}


Function New-RandomPassword {

    param(
        [Parameter(Mandatory=$False,Position=1)]
        [int]$PasswordNrChars = 64
    )

	Process {
		$Iterations = 0
        Do {
			If ($Iterations -ge 20) {
				EXIT
			}
			$Iterations++
			$pwdBytes = @()
			$rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
			Do {
				[byte[]]$byte = [byte]1
				$rng.GetBytes($byte)
				If ($byte[0] -lt 33 -or $byte[0] -gt 126) {
					CONTINUE
				}
                $pwdBytes += $byte[0]
			}
			While ($pwdBytes.Count -lt $PasswordNrChars)
				$NewPassword = ([char[]]$pwdBytes) -join ''
			}
        Until (Test-PasswordIsComplex $NewPassword)
        Return $NewPassword
	}
# End of New-RandomPassword function
}

# Get all the users in the domain, filter out the built-in accounts, and accounts with a blank password, and accounts that are disabled, and accounts without a email address.
$Users = Get-ADUser -Filter * -Properties EmailAddress, PasswordExpired, SamAccountName, GivenName, Surname | Where-Object {
    ($_.Enabled -ne $false) -and
    ($_.EmailAddress -ne $null) -and
    ($_.EmailAddress -ne "") -and
    ($_.givenname -ne "") -and
    ($_.givenname -ne $null) -and
    ($_.Surname -ne "") -and
    ($_.Surname -ne $null) -and
    ($_.samAccountName -like "*wowrack*")
    } | Sort-Object SamAccountName;

# Set the password for each user to a random 16 character password
foreach ($User in $Users) {

    # Generate a random 16 character password
    [int]$PassLength = 12
    # Generate A New Password With The Specified Length (Text)
    [string]$NewPasswordPlain = (New-RandomPassword $PassLength).ToString()
    # Convert the NewKRBTGTPassword to SecureString
    $NewKPasswordSecure = ConvertTo-SecureString -String $NewPasswordPlain -AsPlainText -Force

    # Set the user's password
    Set-ADAccountPassword -Identity $User.SamAccountName -NewPassword $NewKPasswordSecure -Reset;

    Set-Aduser -ChangePasswordAtLogon $true -Identity $User.SamAccountName;

    # Export the user's details to a CSV file
    $UserDetails = [PSCustomObject]@{
        "Name" = $User.Name;
        "SamAccountName" = $User.SamAccountName;
        "EmailAddress" = $User.EmailAddress;
        "Password" = $NewPasswordPlain;
    };
    $UserDetails | Export-Csv -Path "C:\UsersAndNewPasswords.csv" -Append -NoTypeInformation;
}
