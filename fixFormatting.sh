#!/bin/bash
abbrvNL=("PI" "SPI" "NAI" "WCI" "GRI" "ECI" "PI" "CSY" "AAY" "CAY" "NSY" "NWI" "PE" "PWS") # Abbreviations for Native languages.
fileToFormat="$1"

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Current function: Convert an entire text file into a single line."
    echo "[Function] '[Input File]' '[Output File (Optional)]'"
    exit 1
fi

if [ "$#" -eq 2 ]; then
    newFile="$2"
    tr -d '\n' < "$fileToFormat" > "$newFile"
else
    tr -d '\n' < "$fileToFormat" > "$fileToFormat.tmp"
    mv "$fileToFormat.tmp" "$fileToFormat"
fi # File should be all on one line after this.

sed -i -E "s/([0-9]+)([A-Z]{2,3}\b)/\1\n\2/g" "${newFile:-$fileToFormat}" # Page numbers separate

for langTags in "${abbrvNL[@]}"; do
    sed -i -E "s/\b($langTags)\b/\n\1/g" "${newFile:-$fileToFormat}"
done # Should be newlines after each instance of abbrvANL after this.

exit 0

