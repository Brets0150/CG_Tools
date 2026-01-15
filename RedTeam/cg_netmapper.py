# Psudo code for whole script
 # - The script is given a target IP address or IP range or hostname.
 # - The provided target is ping scanned and top 100 ports syn scanned to determine live IPs.
 # - Use results from the port scan and ping scan to create a list of live IPs.
 # - Take the list of live IPs and run a full syn scan of all TCP ports on the live IPs. This will create a list of all open ports for each live IP. The output will be saved to a greppable file with the name <Target>_full_syn_scan_<datetime>.gnmap.
 # - For each live IP with open ports, run a service scan on the open ports to determine the service and version of the service running on all open ports.  The output will be saved to a greppable file with the name <Target>_service_scan_<datetime>.gnmap.
 # - For each live IP with open ports, run a script scan on the open ports to determine if there are any vulnerabilities on the open ports. The output will be saved to a greppable file with the name <Target>_script_scan_<datetime>.gnmap.

import subprocess
import datetime
import os
import sys

def run_command(command):
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        return result.stdout
    except Exception as e:
        print(f"An error occurred: {e}")
        return None

def ping_scan(target):
    print(f"Running ping scan on {target}...")
    command = f"nmap -sn {target}"
    return run_command(command)

def top_ports_scan(target):
    print(f"Running top 100 ports SYN scan on {target}...")
    command = f"nmap -sS --top-ports 100 {target}"
    return run_command(command)

def full_syn_scan(target):
    print(f"Running full SYN scan on {target}...")
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"{target}_full_syn_scan_{timestamp}.gnmap"
    command = f"nmap -sS -p- {target} -oG {output_file}"
    run_command(command)
    return output_file

def service_scan(target, ports):
    print(f"Running service scan on {target}...")
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"{target}_service_scan_{timestamp}.gnmap"
    command = f"nmap -sV -p {ports} {target} -oG {output_file}"
    run_command(command)
    return output_file

def script_scan(target, ports):
    print(f"Running script scan on {target}...")
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    output_file = f"{target}_script_scan_{timestamp}.gnmap"
    command = f"nmap -sC -p {ports} {target} -oG {output_file}"
    run_command(command)
    return output_file

def parse_live_ips(scan_result):
    live_ips = []
    lines = scan_result.split('\n')
    for line in lines:
        if "Host is up" in line:
            ip = line.split()[1]
            live_ips.append(ip)
    return live_ips

def parse_open_ports(scan_result):
    open_ports = []
    lines = scan_result.split('\n')
    for line in lines:
        if "/tcp" in line and "open" in line:
            port = line.split('/')[0]
            open_ports.append(port)
    return open_ports

def main(target):
    # Run ping scan and top ports scan
    ping_scan_result = ping_scan(target)
    top_ports_scan_result = top_ports_scan(target)

    # Get list of live IPs
    live_ips = parse_live_ips(ping_scan_result + top_ports_scan_result)

    for ip in live_ips:
        # Run full SYN scan
        full_syn_scan(ip)

        # Get open ports from the full SYN scan
        open_ports = parse_open_ports(top_ports_scan_result)
        if open_ports:
            open_ports_str = ",".join(open_ports)

            # Run service scan
            service_scan(ip, open_ports_str)

            # Run script scan
            script_scan(ip, open_ports_str)

if __name__ == "__main__":
    # Check for the -t flag passed from the command line, if -t is passed, the target is the next argument
    if "-t" in sys.argv:
        target = sys.argv[sys.argv.index("-t") + 1]
    else:
        target = input("Enter the target IP address, IP range, or hostname: ")
    main(target)
