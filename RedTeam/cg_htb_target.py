#!/usr/bin/env python3
"""
Author: Bret.s
Last Update: 1/15/2026
Version: 0.1
Made In: Kali Rolling
OS Tested: Kali Rolling
Purpose: HTB target reconnaissance and scanning automation

Command Line Usage: ./cg_htb_target.py <target name> <target IP>

Note:
    Requires root privileges for DNS configuration and nmap scans.

Version Change Notes:
    0.1 - Initial Python port from bash script
"""

import argparse
import os
import re
import subprocess
import sys
import time
from pathlib import Path


# Settings
NMAP_SPEED = "T4"


def print_help():
    """Display usage help."""
    print("Usage: ./cg_htb_target.py <target name> <target IP>")
    print("Example: ./cg_htb_target.py 'target.htb' '10.10.11.233'")


def run_command(cmd: list[str], capture_output: bool = False) -> subprocess.CompletedProcess:
    """Run a shell command and return the result."""
    return subprocess.run(cmd, capture_output=capture_output, text=True)


def setup_dns(target_name: str, target_ip: str) -> bool:
    """Configure dnsmasq to resolve target domain to target IP."""
    dns_entry = f"address=/.{target_name}/{target_ip}\n"

    try:
        with open("/etc/dnsmasq.conf", "a") as f:
            f.write(dns_entry)
    except PermissionError:
        print("Error: Need root privileges to modify /etc/dnsmasq.conf")
        return False
    except IOError as e:
        print(f"Error writing to dnsmasq.conf: {e}")
        return False

    # Restart dnsmasq service
    run_command(["systemctl", "stop", "dnsmasq.service"])
    run_command(["systemctl", "start", "dnsmasq.service"])

    # Verify DNS resolution
    result = run_command(["dig", "+short", f"sdfg.{target_name}"], capture_output=True)
    if not result.stdout.strip():
        print("DNS Config did not work, check resolver.conf")
        return False

    print("DNS Good")
    return True


def quick_port_scan(target_ip: str, out_file: str) -> None:
    """Run a quick nmap scan of top 1000 ports."""
    cmd = [
        "nmap", "-Pn", f"-{NMAP_SPEED}",
        "--top-ports", "1000",
        "-oA", f"./{out_file}",
        target_ip
    ]
    run_command(cmd)


def scan_all_ports(target_ip: str, out_file: str) -> None:
    """Run a full nmap scan of all ports."""
    cmd = [
        "nmap", "-Pn", f"-{NMAP_SPEED}",
        "-p-", "--open",
        "-oA", f"./{out_file}",
        target_ip
    ]
    run_command(cmd)


def scan_port_details(gnmap_file: str) -> None:
    """Parse gnmap file and run detailed scans on discovered open ports."""
    gnmap_path = Path(gnmap_file)

    # Validate file
    if not gnmap_path.exists():
        print(f"File does not exist: {gnmap_file}")
        return

    if gnmap_path.stat().st_size == 0:
        print(f"File is empty: {gnmap_file}")
        return

    if gnmap_path.suffix != ".gnmap":
        print("File does not exist or is empty or is not a .gnmap file.")
        return

    timestamp = int(time.time())

    try:
        with open(gnmap_path, "r") as f:
            lines = f.readlines()
    except IOError as e:
        print(f"Error reading file: {e}")
        return

    # Filter lines containing 'Ports:' and 'open'
    for line in lines:
        if "Ports:" not in line or "open" not in line.lower():
            continue

        # Parse host IP from the line
        # Format: Host: <IP> (<hostname>)\tPorts: ...
        parts = line.split("\t")
        if len(parts) < 2:
            continue

        # Extract IP from "Host: <IP> (<hostname>)" or "Host: <IP> ()"
        host_part = parts[0]
        ip_match = re.search(r"Host:\s*(\d+\.\d+\.\d+\.\d+)", host_part)
        if not ip_match:
            continue
        host_ip = ip_match.group(1)

        # Extract ports from "Ports: <port>/<state>/<protocol>/..."
        ports_part = parts[1] if parts[1].startswith("Ports:") else ""
        if not ports_part:
            continue

        # Remove "Ports: " prefix and parse port entries
        ports_data = ports_part[7:].strip()  # Remove "Ports: "
        port_entries = ports_data.split(", ")

        open_ports = []
        for entry in port_entries:
            # Format: <port>/<state>/<protocol>/<owner>/<service>/<rpc>/<version>
            port_info = entry.split("/")
            if len(port_info) >= 1:
                port_num = port_info[0].strip()
                if port_num.isdigit():
                    open_ports.append(port_num)

        if not open_ports:
            continue

        port_list = ",".join(open_ports)
        out_file = f"./{host_ip}_detail-port-scan_{timestamp}"

        cmd = [
            "nmap", "-Pn",
            "-p", port_list,
            "-oA", out_file,
            "-sCV", "-A", "-T3",
            host_ip
        ]
        run_command(cmd)


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="HTB target reconnaissance and scanning automation",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Example: ./cg_htb_target.py -d target.htb -i 10.10.11.233"
    )
    parser.add_argument(
        "-d", "--dns",
        required=True,
        metavar="HOSTNAME",
        help="Target DNS hostname (e.g., target.htb)"
    )
    parser.add_argument(
        "-i", "--ip",
        required=True,
        metavar="ADDRESS",
        help="Target IP address (e.g., 10.10.11.233)"
    )

    args = parser.parse_args()

    target_name = args.dns
    target_ip = args.ip

    # Prepare output file names
    target_ip_name = target_ip.replace("/", "-")
    out_file_quick_scan = f"{target_ip_name}_scan-log"
    out_file_full_scan = f"{out_file_quick_scan}_full"

    # Create target directory and change to it
    target_dir = Path(f"./{target_name}")
    target_dir.mkdir(parents=True, exist_ok=True)
    os.chdir(target_dir)

    # Setup DNS
    if not setup_dns(target_name, target_ip):
        sys.exit(1)

    # Run scans
    quick_port_scan(target_ip, out_file_quick_scan)
    scan_port_details(f"{out_file_quick_scan}.gnmap")

    scan_all_ports(target_ip, out_file_full_scan)
    scan_port_details(f"{out_file_full_scan}.gnmap")

    sys.exit(0)


if __name__ == "__main__":
    main()
