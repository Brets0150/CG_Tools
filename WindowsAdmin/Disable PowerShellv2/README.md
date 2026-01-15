# Disable PowerShell v2
This script will disable the PowerShell v2 Engine on Windows 10/11 or Server 2012/16/19/22.
The script was meant to be run from a GPO startup script, but can be run manually as well.
Here is an overview of what the script does:

 1. Starts logging by defining the path for the log file.
 2. Determines the version of the operating system running on the machine.
 3. Checks if the version of PowerShell v2 is enabled based on the operating system version.
 4. If PowerShell v2 is enabled, it disables the feature and logs whether the process was successful or not.
 5. If PowerShell v2 is already disabled, it logs a message indicating no changes will be made.
 6. Stops logging.

See my blog post for more details: https://cybergladius.com/2021/09/08/powershell-best-practices-for-preventing-abuse/#remove-powershell-v2
