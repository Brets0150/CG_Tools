#!/bin/bash

obfBd() {
    local input="${1}"
    local output="./data.dat"
    # If "${2}" is empty, or has a value less than 1, then use the default vaolume of 42 for the XOR key. Otherwise, use the value of "${2}" as the XOR key.
    if [[ -z "${2}" ]] || [[ "${2}" -lt 1 ]]; then
        local xorKey=42
    else
        local xorKey="${2}"
    fi
    # XOR function
    xor() { K=$1;shift;R="";for i in $@; do R="$R $(($i^$K))";done;echo "$R";}

    # Convert the input to hex, charcode, dec, xor, and bin
    toHex="$(echo -n "${input}" | xxd -ps -c 1 | awk -F '\n' '{OFS=":"; for(i=1;i<=NF;i++) printf "%s%s", "\\x"$i, (i==NF)?"":";"}')"
    echo "HEX: ${toHex}"
    toCharcode="$(echo -n "${toHex}" | od -An -t x1 | tr ' ' ';' | tr -d '\n')"
    echo "CHARCODE: ${toCharcode}"
    toDec="$(echo -n "${toCharcode}" | while IFS= read -r -n1 char; do printf "%d " "'${char}'"; done)"
    echo "DEC: ${toDec}"
    toXor="$(xor ${xorKey} "${toDec}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    echo "XOR: ${toXor}"
    toBin="$(echo -n "${toXor}" | xxd -b -c1 | awk '{print $2}' | tr '\n' ' ')"
    echo "BIN: ${toBin}"
    echo -n "${toBin}" > "${output}"
    echo "Obfuscation complete. Output file: ${output}"
}

# Call the encrypt function with the provided command line argument
obfBd "${1}" "${2}"
