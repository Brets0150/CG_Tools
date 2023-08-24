#!/usr/bin/env bash
#
# Author: Bret.s
# Last Update: 8/24/2023
# Version: 0.1
# Made In: Kali 2 Rolling
# OS Tested: Kali 2 Rolling
# Purpose:
#
# Command Line Usage: ./"
##
# Note:
##
# Version Change Notes.
# 0.1 -
##

targetName="${1}"
targetIP="${2}"

targetIPName="$(echo "${targetIP}"| tr '/' '-')"
outFileQuickScan="${targetIPName}_scan-log"
outFileFullScan="${outFileQuickScan}_full"


# Settings
nmapSpeed='T4'

cmdHelp(){
    echo "Usage: ./cg_htb_target.sh <target name> <target IP>"
    echo "Example: ./cg_htb_target.sh 'target.htb' '10.10.11.233'"
}

if [ "${targetName}" == '' ]; then echo "missing target name..";cmdHelp;exit 1;fi
if [ "${targetIP}" == '' ]; then echo "missing target IP..";cmdHelp;exit 1;fi

# Create target directory.
mkdir -p "./${targetName}"
cd "./${targetName}" || exit 1

# Set DNS to resolve to target IP.
echo "address=/.${targetName}/${targetIP}" >>/etc/dnsmasq.conf
systemctl stop dnsmasq.service && systemctl start dnsmasq.service
if [ -z "$(dig +short "sdfg.${targetName}")" ];then echo 'DNS Config did not work, check resolver.conf';exit 1;else echo 'DNS Good' ;fi


fun_quickPortScan(){
    #
    nmap -Pn -${nmapSpeed} --top-ports 1000 -oA "./${outFileQuickScan}" ${targetIP}
}

fun_scanAllPorts(){
    #
    nmap -Pn -${nmapSpeed} -p- --open -oA "./${outFileFullScan}" ${targetIP}
}

fun_scanPortDetails(){
    tmp_ipList="${1}"
    time=$(date +%s)
    # confirm file exists, is not empty, has the extention '.gnmap'.
    if [ ! -s "${tmp_ipList}" ] || [ "${tmp_ipList##*.}" != 'gnmap' ]; then
        echo "File does not exist or is empty or is not a .gnmap file."
        exit 1
    fi

    declare -a ary_linesOfFile ary_tmp_openPort
    readarray -t ary_linesOfFile <<<"""$(grep 'Ports:' "./${tmp_ipList}" |grep -i open)"""
    for str_tmp_line in "${ary_linesOfFile[@]}";do
        # Put Host IP in to array.
        str_hostIP="$(echo "${str_tmp_line}"|awk -F'\t' '{print $1}'|tr -d '(\|)\| '|cut -c 6-)"
        # Parse data to form NMap ready variable of open ports.
        readarray -d ',' ary_tmp_openPort <<<"""$(echo "${str_tmp_line}"|awk -F'\t' '{print $2}'|tr -d '(\|)\| '|cut -c 7-)"""
        str_nmapPortList=''
        for str_port in "${ary_tmp_openPort[@]}";do
            str_tmp_ports="$(echo "${str_port}"|awk -F'/' '{print $1}')"
            str_nmapPortList+="${str_tmp_ports},"
        done
        str_openPort="${str_nmapPortList:0:-1}"
        #
        nmap -Pn -p "${str_openPort}" -oA "./${str_hostIP}_detail-port-scan_${time}" -sCV -A -T3 "${str_hostIP}"
    done
}


fun_quickPortScan
fun_scanPortDetails "${outFileQuickScan}.gnmap"
fun_scanAllPorts
fun_scanPortDetails "${outFileFullScan}.gnmap"
exit 0