#!/bin/bash

obfBd() {
    # Variable to store the plain text input
    local inputPayload="${1}"

    # Variable to store the output file path
    local outputFile="./data.dat"

    # Colors for output
    RED='\033[0;31m'
    NC='\033[0m' # No Color

    # If "${2}" is empty, or has a value less than 1, then use the default vaolume of 42 for the XOR key. Otherwise, use the value of "${2}" as the XOR key.
    if [[ -z "${2}" ]] || [[ "${2}" -lt 1 ]]; then
        local xorKey=42
    else
        local xorKey="${2}"
    fi
    # XOR function using a bitwise XOR operation.
    xor(){
        xorKey="$1"
        shift
        R=""
        for i in $@; do
            # Xor the decimal with the XOR key. Bitwise XOR operation.
            R="$R "$(($i^$xorKey))""
        done
        # Return the result.
        echo "$R"
    }

    # Convert the plain text input to hex
    Hex="$(echo -n "${inputPayload}" | xxd -ps -c 1 | awk -F '\n' '{OFS=":"; for(i=1;i<=NF;i++) printf "%s%s", "\\x"$i, (i==NF)?"":";"}')"
    printf "${RED}Hex:${NC}";echo "${Hex}"

    # Convert the hex to charcode
    Charcode="$(echo -n "${Hex}" | od -An -t x1 | tr ' ' ';' | tr -d '\n')"
    printf "${RED}Charcode:${NC} ${Charcode}\n"

    # Convert the charcode to decimal
    Decimal="$(echo -n "${Charcode}" | while IFS= read -r -n1 char; do printf "%d " "'${char}'"; done)"
    printf "${RED}Decimal:${NC} ${Decimal}\n"

    # XOR the decimal with the XOR key
    Xor="$(xor "${xorKey}" "${Decimal}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    printf "${RED}XOR Decimal:${NC} ${Xor}\n"

    # Convert the XOR'd decimal to binary
    Binary="$(echo -n "${Xor}" | xxd -b -c1 | awk '{print $2}' | tr '\n' ' ')"
    printf "${RED}Binary:${NC} ${Binary}\n"

    # Write the binary to the output file
    echo -n "${Binary}" > "${outputFile}"
    printf "${RED}Obfuscation complete. Output file:${NC} ${outputFile}"
}

# This function is a slimmed down version of the above function. It does not include the intermediate steps.
obfBdSlim() {
    if [[ -z "${2}" ]] || [[ "${2}" -lt 1 ]];then k=42;else k="${2}";fi
    for i in $(echo -n "${1}"|xxd -ps -c 1|awk -F '\n' '{OFS=":"; for(i=1;i<=NF;i++) printf "%s%s", "\\x"$i, (i==NF)?"":";"}' \
    |od -An -t x1|tr ' ' ';'|tr -d '\n'|while IFS= read -r -n1 c; do printf "%d " "'${c}'";done); do R="$R (($i^$k))";done
    sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'<<<"$R"|xxd -b -c1|awk '{print $2}'|tr '\n' ' ' >"./data.dat"
}


# Call the encrypt function with the provided command line argument
obfBd "${1}" "${2}"
# obfBdSlim "${1}" "${2}"
