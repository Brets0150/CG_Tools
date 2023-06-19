#!/bin/bash
# Testing ChatGPT Backdoor. This code does not work.

encode_string() {
  local input="$1"
  local output="encoded.txt"
  local hex_key="42"

  echo "Original String: $input"

  hex_encoded=$(printf "%s" "$input" | xxd -p -c 0 | sed 's/\(..\)/\\x\1/g')
  echo "Hex Encoded String: $hex_encoded"

  charcode_encoded=$(echo "$hex_encoded" | awk -v OFS=';' '{ for (i=1; i<=NF; i++) printf "%d;", "0x" $i }' | sed 's/;$//')
  echo "Charcode Encoded String: $charcode_encoded"

  xor_encoded=$(echo "$charcode_encoded" | awk -v key="$hex_key" -F ";" '{ for (i=1; i<=NF; i++) { value = strtonum($i) ^ strtonum("0x" key); printf "%02X;", value } }')
  echo "XOR Encoded String: $xor_encoded"

  binary_encoded=$(echo "$xor_encoded" | awk -F ";" '{ for (i=1; i<=NF; i++) printf "%08d;", strtonum("0x" $i) }')
  echo "Binary Encoded String: $binary_encoded"

  echo "$binary_encoded" > "$output"
  echo "Encoded string saved to $output"
}

decode_file() {
  local input="$1"
  local output="decoded.txt"
  local hex_key="42"

  binary_encoded=$(cat "$input")
  echo "Binary Encoded String: $binary_encoded"

  xor_encoded=$(echo "$binary_encoded" | awk -F ";" '{ for (i=1; i<=NF; i++) printf "%02X;", strtonum("0b" $i) }')
  echo "XOR Encoded String: $xor_encoded"

  charcode_encoded=$(echo "$xor_encoded" | awk -F ";" '{ for (i=1; i<=NF; i++) printf "%d;", "0x" $i }' | sed 's/;$//')
  echo "Charcode Encoded String: $charcode_encoded"

  hex_encoded=$(echo "$charcode_encoded" | awk -v key="$hex_key" -F ";" '{ for (i=1; i<=NF; i++) { value = strtonum($i) ^ strtonum("0x" key); printf "%02X;", value } }')
  echo "Hex Encoded String: $hex_encoded"

  original_string=$(echo "$hex_encoded" | xxd -r -p | sed 's/\\x//g')
  echo "Decoded String: $original_string"

  echo "$original_string" > "$output"
  echo "Decoded file saved to $output"
}

# Usage examples
encode_string "Hello World"
decode_file "encoded.txt"



cat ./encoded.txt
cat ./decoded.txt