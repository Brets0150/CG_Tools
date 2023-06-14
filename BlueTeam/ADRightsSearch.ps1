#Requires -RunAsAdministrator
<#
.SYNOPSIS

.VERSION
    1.0.0

.DESCRIPTION
    A script to look for AD objects with extended rights.

.EXAMPLE
    PS C:\> .\WindowsIrLogExport.ps1
.LINK
    https://github.com/Brets0150/CG_Tools/
    https://learn.microsoft.com/en-us/previous-versions/tn-archive/ff405676(v=msdn.10)
.NOTES
    Author: Bret.s AKA: CyberGladius / License: MIT
#>

Import-Module ActiveDirectory;

# Define AD locations
$Root = [ADSI]"LDAP://RootDSE"
$DomainPath = "AD:" + ($Root.DefaultNamingContext).ToString();
$DomainControllerPath = "AD:OU=Domain Controllers," + ($Root.DefaultNamingContext).ToString();

[System.Collections.ArrayList]$PathsToCheck = @();
[void]$PathsToCheck.Add($DomainPath);
[void]$PathsToCheck.Add($DomainControllerPath);

# The extended rights to look for
$ExtendedRightsCheck = "1131f6ad-9c07-11d1-f79f-00c04fc2dcd2";

# Define array to save identities to
[System.Collections.ArrayList]$UsersWithExtendedRights = @();

foreach ($PathToCheck in $PathsToCheck) {

    # Get ACEs
    $Aces = (Get-Acl -Path $PathToCheck).Access | Where-Object {(($_.ObjectType -eq $ExtendedRightsCheck) -and ($_.AccessControlType -eq "Allow"))};

    foreach ($Ace in $Aces) {

        [void]$UsersWithExtendedRights.Add(($Ace.IdentityReference).ToString());
    }
}

# Remove duplication
$UsersWithExtendedRights =  $UsersWithExtendedRights | Select-Object -Unique



# For each user with extended rights, get the user's AD details, name, SID, description, DisplayName, and DistinguishedName, OU, and Domain.
foreach ($UserWithExtendedRights in $UsersWithExtendedRights) {

    # Get the user's AD details
    $User = Get-ADUser -Identity $UserWithExtendedRights -Properties *;

    # Get the user's name
    $UserName = $User.Name;

    # Get the user's SID
    $UserSID = $User.SID;

    # Get the user's description
    $UserDescription = $User.Description;

    # Get the user's DisplayName
    $UserDisplayName = $User.DisplayName;

    # Get the user's DistinguishedName
    $UserDistinguishedName = $User.DistinguishedName;

    # Get the user's OU
    $UserOU = $UserDistinguishedName.Split(",")[1];

    # Get the user's Domain
    $UserDomain = $UserDistinguishedName.Split(",")[2];

    # Create a custom object with the user's details
    $UserDetails = New-Object -TypeName PSObject;
    $UserDetails | Add-Member -MemberType NoteProperty -Name "Name" -Value $UserName;
    $UserDetails | Add-Member -MemberType NoteProperty -Name "SID" -Value $UserSID;
    $UserDetails | Add-Member -MemberType NoteProperty -Name "Description" -Value $UserDescription;
    $UserDetails | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $UserDisplayName;
    $UserDetails | Add-Member -MemberType NoteProperty -Name "DistinguishedName" -Value $UserDistinguishedName;
    $UserDetails | Add-Member -MemberType NoteProperty -Name "OU" -Value $UserOU;
    $UserDetails | Add-Member -MemberType NoteProperty -Name "Domain" -Value $UserDomain;

    # Output the user's details
    $UserDetails;
}



 # Maybe this code???
 # Import Active Directory module
Import-Module ActiveDirectory

# Retrieve the current domain information
$root = [ADSI]"LDAP://RootDSE"
$domain = $root.Get("defaultNamingContext")
$ldapPath = "ad:/$domain"


# Get the access control list (ACL) for the specified Active Directory path
$accessControlList = Get-Acl "$ldapPath"

# Filter the ACEs to get only those with IdentityReference and specific ObjectTypes or ActiveDirectoryRights
$filteredACEs = $accessControlList.Access | Where-Object {
    $_.IdentityReference -and (
        $_.ObjectType -eq "1131f6aa-9c07-11d1-f79f-00c04fc2dcd2" -or 
        $_.ObjectType -eq "1131f6ad-9c07-11d1-f79f-00c04fc2dcd2" -or
        $_.ObjectType -eq "89e95b76-444d-4c62-991a-0facbeda640c" -or 
        $_.ActiveDirectoryRights -match "WriteDacl" -or 
        $_.ActiveDirectoryRights -contains "GenericAll"
    )
}

# Output the filtered ACEs
$filteredACEs
