#!/bin/bash

# Abbreviations for Native languages.
abbrvNL=("PI" "SPI" "NAI" "WCI" "GRI" "ECI" "PI" "CSY" "AAY" "CAY" "NSY" "NWI" "PE" "PWS") 

fontSymbols=("p" "t" "k" "kw" "q" "qw" "v" "l" "z" "y" "$" "!" "!w" "3" "3w" "f" "@" "s" "5" "x" "xw" "X" "Xw" "h" "m" "n" "&" "&w" "6" "%" "7" "7w" "i" "u" "0" "a" "4" "9" "\\")
CSYReplacements=("p" "t" "k" "" "q" "" "v" "l" "s" "y" "" "g" "ug (ligature)" "r" "" "vv" "ll" "ss" "" "gg" "w" "rr" "" "h" "m" "n" "ng" "" "ḿ" "ń" "ńg" "" "i" "u" "e" "a" "" "" "")
APAReplacements=("p" "t" "k" "kʷ" "q" "qʷ" "v" "l" "z" "y" "ž" "ɣ" "ɣʷ" "ʀ" "ʀʷ" "f" "ł" "s" "š" "x" "xʷ" "X" "Xʷ" "h" "m" "n" "ŋ" "ŋʷ" "m̥" "n̥" "ŋ̥" "ŋ̥ʷ" "i" "u" "ə" "a" "ɨ" "ð" "R̃")
IPAReplacements=($'p' $'t' $'k' $'k\u02B7' $'q' $'q\u02B7' $'v' $'\u03B8' $'z' $'j' $'\u0290' $'\u0263' $'\u0263\u02B7' $'\u0281' $'\u0281\u02B7' $'f' $'\u026C' $'s' $'\u0282' $'x' $'x\u02B7' $'\u03C7' $'X\u02B7' $'h' $'m' $'n' $'\u014B' $'\u014B\u02B7' $'m\u0325' $'n\u0325' $'\u014B\u0325' $'\u014B\u0325\u02B7' $'i' $'u' $'\u0259' $'a\u0308' $'\u0268' $'\u00F0' $'\u0274')

function replaceSymbolsInColumn() {
    local inputFile="$1"
    local columnNumber="$2"
    local replacementArrayName="$3"
    declare -n cleanupArray="$replacementArrayName"

    if [ ${#cleanupArray[@]} -eq 0 ]; then
        echo "Error: Replacement array '$replacementArrayName' is empty." >&2; return 1
    fi

    # Sort by length
    local sortedIndices=$(for i in "${!fontSymbols[@]}"; do [ -n "${fontSymbols[$i]}" ] && echo "${#fontSymbols[$i]} $i"; done | sort -rn | awk '{print $2}')

    local numCols=$(head -n 1 "$inputFile" | awk '{print NF}')
    local pasteArgs=""
    for ((i=1; i<=numCols; i++)); do
        cut -f"$i" "$inputFile" > "$inputFile.col$i.tmp"
        pasteArgs="$pasteArgs $inputFile.col$i.tmp"
    done

    local targetFile="$inputFile.col$columnNumber.tmp"
    for i in $sortedIndices; do
        local preSymbols=$(sed -e 's/[$\\]/\\&/g' <<<"${fontSymbols[i]}")
        local postSymbols="${cleanupArray[i]}"
        postSymbols=$(sed -e 's/[&\\/]/\\&/g' <<<"$postSymbols")
        sed -i -E "s#$preSymbols#$postSymbols#g" "$targetFile"
    done

    paste $pasteArgs > "$inputFile"
    rm $pasteArgs
}

inputFile="$1"

if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 '[Input File]' '[Output File (Optional)]' '[Cleanup Format (CSY/APA/IPA)]'"
    echo "Use -t flag to test symbol array sizes."
    exit 1
fi

if [ "$1" == "-t" ]; then
    size0=${#fontSymbols[@]}; size1=${#CSYReplacements[@]}; size2=${#APAReplacements[@]}; size3=${#IPAReplacements[@]}
    echo -e "Sizes: Font Symbols:$size0 CSY:$size1 APA:$size2 IPA:$size3"
    exit 0
fi


if [ "$#" -eq 1 ]; then
    outputFile="$inputFile"
    tempFile="$inputFile.tmp"
    cp "$inputFile" "$tempFile"
    tr -d '\n' < "$tempFile" > "$outputFile"
else
    outputFile="$2"
    tr -d '\n' < "$inputFile" > "$outputFile"
fi


sed -i -E "s/([0-9]+)([A-Z]{2,3}\b)/\1\n\2/g" "$outputFile"
for langTag in "${abbrvNL[@]}"; do
    sed -i -E "s/\b($langTag)\b/\n\1/g" "$outputFile";
done # Should be newlines after each instance of abbrvNL after this.

# Divide into page number, language tag, Yupik, and notes.
awk 'BEGIN { FS=" "; OFS="\t"; currentPage="" }
{
    if ($0 ~ /^[0-9]+$/) { currentPage = $0; next; }
    if ($0 ~ /^[A-Z]+ / || $0 ~ /^[A-Z]+$/) {
        tag = $1; rest = substr($0, length(tag) + 2);
        noteRegex = "('\''[^'\'']*'\''|\\[[^\\]]*\\])";
        while (length(rest) > 0) {
            gsub(/^[ \t,]+/, "", rest); if (length(rest) == 0) break;
            yupikEntry = ""; notes = "";
            if (match(rest, noteRegex)) {
                yupikEntry = substr(rest, 1, RSTART-1);
                notes = substr(rest, RSTART, RLENGTH);
                rest = substr(rest, RSTART + RLENGTH);
                gsub(/^[ \t,]+/, "", rest);
                while (match(rest, "^" noteRegex)) {
                    notes = notes " " substr(rest, RSTART, RLENGTH);
                    rest = substr(rest, RSTART + RLENGTH); gsub(/^[ \t,]+/, "", rest);
                }
            } else { yupikEntry = rest; rest = ""; }
            gsub(/^[ \t,]+|[ \t,]+$/, "", yupikEntry); gsub(/^[ \t,]+|[ \t,]+$/, "", notes);
            if (length(yupikEntry) > 0 || length(notes) > 0) print currentPage, tag, yupikEntry, notes;
        }
    }
}' "$outputFile" > "$outputFile.awk.tmp" && mv "$outputFile.awk.tmp" "$outputFile"

if [ "$#" -eq 3 ]; then
    cleanupTypeInput="$3"
    if [ "$cleanupTypeInput" == "IPA" ]; then
    	arrayName="IPAReplacements"
    elif [ "$cleanupTypeInput" == "APA" ]; then
	arrayName="APAReplacements"
    else 
	arrayName="CSYReplacements"; 
	  if [ "$cleanupTypeInput" != "CSY" ]; then
	     echo "Defaulting to CSY..."
	  fi
    fi
    replaceSymbolsInColumn "$outputFile" 3 "$arrayName"
    replaceSymbolsInColumn "$outputFile" 4 "$arrayName" # Need to make decision on how to either divide columns further or selectively translate format symbols w/o ruining English
fi

exit 0
