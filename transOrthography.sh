#!/bin/bash

CSYchars=("p" "t" "k" "kw" "q" "qw" "v" "l" "z" "y" "r" "g" "w" "gh" "ghw" "f" "ll" "s" "rr" "gg" "wh" "ghh" "ghhw" "h" "m" "n" "ng" "ngw" "mm" "nn" "ngng" "ngngw" "i" "u" "e" "a")
IPAchars=($'p' $'t' $'k' $'k\u02B7' $'q' $'q\u02B7' $'v' $'l' $'z' $'j' $'\u0290' $'\u0263' $'\u0263\u02B7' $'\u0281' $'\u0281\u02B7' $'f' $'\u026C' $'s' $'\u0282' $'x' $'x\u02B7' $'\u03C7' $'X\u02B7' $'h' $'m' $'n' $'\u014B' $'\u014B\u02B7' $'m\u0325' $'n\u0325' $'\u014B\u0325' $'\u014B\u0325\u02B7' $'i' $'u' $'\u0259' $'a')

declare -A CSYIPA
for i in "${!CSYchars[@]}"; do
	if [ -n "${CSYchars[$i]}" ]; then
		CSYIPA["${CSYchars[$i]}"]="${IPAchars[$i]}"
	fi
done

sortedTokens=$(for key in "${!CSYIPA[@]}"; do echo "${#key} $key"; done | sort -rn | awk '{print $2}')
readarray -t tokenSearchOrder <<< "$sortedTokens"

function convertIPA() {
	local tempWord="$1"
	local convertedWord=""

	while [ -n "$tempWord" ]; do
		local foundToken=false

		for token in "${tokenSearchOrder[@]}"; do
			if [[ "${tempWord,,}" == "${token}"* ]]; then
				convertedWord+="${CSYIPA[$token]}"
				tempWord="${tempWord:${#token}}"
				foundToken=true
				break
			fi
		done

		if ! $foundToken; then
			convertedWord+="${tempWord:0:1}"
			tempWord="${tempWord:1}"
		fi
    	done
    
    echo "$convertedWord"
}

if [[ "$#" -lt 1 ]] || [[ "$#" -gt 2 ]] ; then
	echo "Function: Enforces transparent orthography for Central Siberian Yupik files with IPA."
	echo "Usage: $0 [inputFile] [outputFile (Optional)]"
	exit 0
fi

inputFile="$1"

if [[ "$#" -eq 1 ]] ; then
	outputFile="$inputFile"
elif [[ "$#" -eq 2 ]] ; then
	outputFile="$2"
	cp "$inputFile" "$outputFile"
fi

tempFile="${outputFile}.temp"
cp "$outputFile" "$tempFile"

> "$outputFile"
while IFS= read -r line || [[ -n "$line" ]]; do
	convertedLine=""
	for word in $line; do
		converted=$(convertIPA "$word")
		convertedLine+="$converted "
	done

	echo "${convertedLine% }" >> "$outputFile"

done < "$tempFile"

rm "$tempFile"

echo "Done. Check for transparent orthography in $outputFile."
exit 0
