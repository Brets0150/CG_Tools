#!/bin/bash
# Author: @Bret0150 (AKA: CyberGladius)
# Date: 2024-07-02

# Used to find vulnerable SSH servers to CVE-2024-6387.

tstamp=$(date +"%Y%m%d_%H%M%S")
outFile_Name="mscan__${tstamp}__.grep.txt"
ip_w_ssh_file="./ip_w-sh__${tstamp}__.txt"
nmap_out_file="./nmap__${tstamp}__.grep.txt"
vuln_list="./vuln_ssh__${tstamp}__.txt"
scan_log="./scan_log__${tstamp}__.txt"
ip_list=false

# Check if masscan and nmap are installed.
if ! command -v masscan &> /dev/null; then
    echo "masscan could not be found. Please install masscan."
    exit 1
fi

# Confirm script is running as root.
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Check if an IP, IP range, or text file with IPs was provided via command line argument.
if [ -z "$1" ]; then
    echo "Usage: $0 <IP|IP range|file with IPs>"
    exit 1
fi

# Check if the flag '-v' was provided. If so, set verbose to true.


# Check if the provided argument is a file.
if [ -f "$1" ]; then
    ip_list=true
fi

# if the provided argument is a file, set the massscan command to scan the IPs in the file.
if [ "$ip_list" = true ]; then
    masscan --include-file "${1}" -p22 --open-only -oG "${outFile_Name}"
else
    # scan subnets for port 22
    masscan "${1}" -p22 --open-only -oG "${outFile_Name}"
fi

# Filter for IPs with port 22 open to form a list of IPs with SSH open.
grep -oP '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b' "${outFile_Name}" | sort -u > "${ip_w_ssh_file}"

# Use nmap to get the SSH version of the IPs with SSH open.
nmap -iL "${ip_w_ssh_file}" -p22 -sV -oG "${nmap_out_file}"

# Flter for Port lines.

grep 'Ports: 22/open/tcp' "${nmap_out_file}" | while IFS= read -r line; do
    tmp_ip="$(echo "${line}" | grep -oP '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b')"
    tmp_ver="$(echo "${line}" | grep -oP 'OpenSSH \K[0-9]+\.[0-9]+(?:p[0-9]+)?')"

    if [ -n "$tmp_ver" ]; then
        version=$tmp_ver
        if [[ "$version" =~ ^([0-9]+)\.([0-9]+)(p[0-9]+)?$ ]]; then
            major=${BASH_REMATCH[1]}
            minor=${BASH_REMATCH[2]}
            patch=${BASH_REMATCH[3]:-0}  # default to 0 if no patch level

            # Check vulnerability conditions
            if (( major < 4 )) || (( major == 4 && minor < 4 )); then
                status="\e[31m$version is vulnerable (older than 4.4p1)\e[0m"
                echo "${tmp_ip}" >> "${vuln_list}"

            elif (( major == 8 && minor > 5 )) || (( major == 9 && minor < 8 )); then
                status="\e[31m$version is vulnerable (between 8.6p1 and 9.7p1)\e[0m"
                echo "${tmp_ip}" >> "${vuln_list}"

            else
                status="$version is NOT vulnerable (4.4p1 to 8.5p1)"
            fi
        else
            status="Invalid version format: $version"
        fi
        echo -e "${tmp_ip}: ${status}" | tee -a "${scan_log}"
    fi
done

exit 0