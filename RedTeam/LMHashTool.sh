#!/bin/bash
##  !/usr/bin/env bash
#
# Author: Bret.s
# Last Update: 10/15/2023
# Version: 1.0
# Made In: Kali 2 Rolling
# OS Tested: Kali 2 Rolling
# Purpose: This script is used to prepare LM hashes for cracking. It will take a file with LM hashes(one hash per line in file) that are 32 characters long and split(-s option) them into two hashes, then save them to a new file.
#           After cracking is done, you can use the script to combine(-c option) the two cracked ashes back into one hash and the ocompanied password to reveale the full password.
#           The cracked hashes file must have the password in the same line as the hash seporated by a colon(:); example: "HASH:PASSWORD", "27F79A76DB247467:SNOOPY". You must have the original hash file to use the combine option.
#
# Command Line Usage: ./LMHashTool.sh <options> <LMHashFile>
##
# Note:
##
# Version Change Notes.
# 1.0 - Done main purpose of script.
##
# Set script current build version.
str_version="1.0"

# Set basic varables for script.
str_scriptsName="${0}"
# Set current date and time logging.
str_datetime="$(date +%s)"

# Help function for script.
function fun_help(){
    echo "Usage: ${str_scriptsName} -l <LMHashFile> <option>"
    echo "  Example: ${str_scriptsName} -l hashes.txt -s"
    echo "  Example: ${str_scriptsName} -l hashes.txt -c cracked.txt"

    echo 'Options:'
    echo '  -s, --split         Split LM hashes into two hashes.'
    echo '  -c, --combine       Combine two hashes into one hash. Requires cracked hashes file.'
    echo '                      Example: "HASH:PASSWORD", "27F79A76DB247467:SNOOPY" One hash per line.'
    echo '  -l, --lmhashes      File with unsplit hashes.'
    echo '  -v, --version       Print script version.'
    echo '  -h, --help          Print this help message.'
}

# Function to output script version.
function fun_version(){
    echo "${str_scriptsName} version: ${str_version}"
}

# A Function to split LM hashes of a file. Each line of the file will contain one hash that is 32 characters long string.
#  Split the 32 character string into two 16 character strings and save them to a new file called "split_hashes_${str_date}_.txt".
function fun_split(){
    local str_outputFile hashes
    # Check that $1 is not empty.
    if [ -z "$1" ]; then
        echo "Error: No file name passed to fun_split function."
        exit 1
    fi
    # Set Output file name.
    str_outputFile="split_hashes_${str_datetime}_.txt"
    # Create a new file to save the split hashes to.
    touch "${str_outputFile}"
    # Set the $hashes variable to empty.
    hashes=''
    # Loop through each line of the file.
    while read -r str_line; do
        # Remove any white space and hidden characters from the line.
        str_line="${str_line//[$'\t\r\n ']}"
        # Confirm the line is 32 characters long. If not, skip the line.
        if [ "${#str_line}" -ne 32 ]; then
            continue
        fi
        # Split the $str_line varaiable into two hashes and append them to the $hashes variable. Add a newline after each hash.
        hashes+="${str_line:0:16}"
        hashes+=$'\n'
        hashes+="${str_line:16:16}"
        hashes+=$'\n'
    done < "$1"
    # Remove duplicate and sort the $hashes variable.
    hashes="$(echo "${hashes}" | tr ' ' '\n' | sort -u)"
    # Output the $hashes variable to the "${str_outputFile}" file.
    echo "${hashes}" > "${str_outputFile}"
    # Tell the user the file was created.
    echo "File ${str_outputFile} created with the split LM hashes."
}

# This function will take the original hashes file, for each line split the 32 character hash into two 16 character hashes called ${str_hash1} and ${str_hash2},
#  Then for ${str_hash1} and ${str_hash2} search the cracked hashes file for for a matching hash, if found, read the crack password(the value after ':') ,
#  and combine the two hashes("${str_hash1}${str_hash2}"") and the password into one line.
function fun_combine(){
    local str_hash1 str_hash2 str_originalHash str_crackedHashes
    # Set the ${str_crackedHashes} variable to the first argument passed to the function.
    str_crackedHashes="$1"
    # set the ${str_originalHash} variable to the second argument passed to the function.
    str_originalHash="$2"
    # Check that ${str_crackedHashes} and ${str_originalHash} are files.
    if [ ! -f "${str_crackedHashes}" ] || [ ! -f "${str_originalHash}" ]; then
        echo "Error: File ${str_crackedHashes} or ${str_originalHash} does not exist or is empty."
        exit 1
    fi

    # For each line of the "${str_originalHash}" file do the following.
    # Remove any white space and hidden characters from the line.
    # Split first 16 character hash into ${str_hash1} and second 16 character hash into ${str_hash2}.
    # Search the "${str_crackedHashes}" file for ${str_hash1}, if found, read the crack password(the value after ':') into ${str_password1}.
    # Search the "${str_crackedHashes}" file for ${str_hash2}, if found, read the crack password(the value after ':') into ${str_password2}.
    # If ${str_password1} and ${str_password2} are not empty, combine the two hashes("${str_hash1}${str_hash2}"") and the password into one line and output it to the screen.
    while read -r str_line; do
        str_line="${str_line//[$'\t\r\n ']}"
        str_hash1="${str_line:0:16}"
        str_hash2="${str_line:16:16}"
        # If str_hash1 equals "AAD3B435B51404EE" then str_password1 is set to ""(empty), else search the "${str_crackedHashes}" file for str_hash1 and read the crack password(the value after ':') into str_password1.
        if [ "${str_hash1}" == "AAD3B435B51404EE" ]; then
            str_password1=""
        else
            str_password1="$(grep "${str_hash1}" "${str_crackedHashes}" | cut -d ':' -f2)"
        fi
        # if str_hash2 equals "AAD3B435B51404EE" then str_password2 is set to ""(empty), else search the "${str_crackedHashes}" file for str_hash2 and read the crack password(the value after ':') into str_password2.
        if [ "${str_hash2}" == "AAD3B435B51404EE" ]; then
            str_password2=""
        else
            str_password2="$(grep "${str_hash2}" "${str_crackedHashes}" | cut -d ':' -f2)"
        fi
        if [ -n "${str_password1}" ] && [ -n "${str_password2}" ]; then
            echo "${str_hash1}${str_hash2}:${str_password1}${str_password2}"
        fi
    done < "${str_originalHash}"
}

# Check if no arguments were passed to the script.
if [ $# -eq 0 ]; then
    fun_help
    exit 0
fi

# Main loop: Check the flags the user passed to the script and run the appropriate function.
while getopts 'sc:l:vh' opt; do
  case "$opt" in
    l)
      str_lmHashFile="${OPTARG}"
      # Check if the "${str_lmHashFile}" file exists and not empty.
        if [ ! -f "${str_lmHashFile}" ]; then
            echo "Error: File ${str_lmHashFile} does not exist or is empty."
            exit 1
        fi
      ;;

    s)
      # Check that the "${str_lmHashFile}" variable is not empty.
        if [ -z "${str_lmHashFile}" ]; then
            echo "Error: No file name passed to -l option."
            exit 1
        fi
        fun_split "${str_lmHashFile}" && exit 0
      ;;

    c)
        # Check that the "${str_lmHashFile}" variable is not empty.
        if [ -z "${str_lmHashFile}" ]; then
            echo "Error: No file name passed to -l option."
            exit 1
        fi

        str_crackedHashes="$OPTARG"
        # Check that ${str_crackedHashes} file exists and not empty.
        if [ -z "${str_crackedHashes}" ]; then
            echo "Error: File ${str_crackedHashes} does not exist or is empty."
            exit 1
        fi
        fun_combine "${str_crackedHashes}" "${str_lmHashFile}" && exit 0
      ;;
    v)
        fun_version
        exit 0
        ;;
    ?|h)
      fun_help
      exit 0
      ;;
  esac
done

exit 0