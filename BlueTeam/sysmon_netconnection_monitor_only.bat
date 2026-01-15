@echo off
:: - SYSMON installer + Network Connection Monitor scripts.
:: --- This sysmon config will log all network connections and nothing else.
:: --- This is meant to track down issues or random connections temporarily.
::
:: - Managed By Bret.S

:: Force override the existing network connections sysmon configuration.

:: - Variables for script.
set str_domainName=SDPServer.testdomain.com
set str_sysmonSDP=sdp$\sysmon

:: Check for arguments passed to the script.
set arg1=%1

:: - Check if running as an Admin
net.exe session 1>NUL 2>NUL || (Echo This script requires elevated rights. & Exit /b 1)

:: - Check is the SysMon DNS config file exists, if not make it.
if not exist "C:\WINDOWS\config-netconn.xml" ( GOTO InstallConfig )

if %arg1%=="force" ( GOTO InstallConfig )

:: - Check is SysMon is running
sc query "Sysmon64" | Find "RUNNING"
If "%ERRORLEVEL%" EQU "1" (
goto StartSysmon
)

:InstallConfig
(
echo ^<Sysmon schemaversion="14.22"^>
echo  ^<EventFiltering^>
echo   ^<NetworkConnect onmatch="exclude" /^>
echo  ^</EventFiltering^>
echo ^</Sysmon^>
) > C:\WINDOWS\config-netconn.xml

:: - Check if SysMon is installed, if not install it.
:StartSysmon
net start sysmon64
If "%ERRORLEVEL%" EQU "1" (
goto InstallSysmon
) else (
goto LoadNetConnConfig
)

:: - Install the SysMon agent from the SDP point.
:InstallSysmon
"\\%str_domainName%\%str_sysmonSDP%\Sysmon64.exe" -i -accepteula
If "%ERRORLEVEL%" EQU "1" (
echo "An Error occured while installing SysMon."
pasue
) else ( goto LoadNetConnConfig )

:: - Load the Network Connections Config into SysMon
:LoadNetConnConfig
"C:\WINDOWS\Sysmon64.exe" -c "C:\WINDOWS\config-netconn.xml"
If "%ERRORLEVEL%" EQU "1" (
echo "An Error occured while loading the SysMon Config."
pasue
)

exit 0