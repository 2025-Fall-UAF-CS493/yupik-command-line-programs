#!/bin/bash

lineNum=0

CSYchars=("p" "t" "k" "kw" "q" "qw" "v" "l" "z" "y" "r" "g" "w" "gh" "ghw" "f" "ll" "s" "rr" "gg" "wh" "ghh" "ghhw" "h" "m" "n" "ng" "ngw" "mm" "nn" "ngng" "ngngw" "i" "u" "e" "a")
IPAchars=($'p' $'t' $'k' $'k\u02B7' $'q' $'q\u02B7' $'v' $'l' $'z' $'j' $'\u0290' $'\u0263' $'\u0263\u02B7' $'\u0281' $'\u0281\u02B7' $'f' $'\u026C' $'s' $'\u0282' $'x' $'x\u02B7' $'\u03C7' $'X\u02B7' $'h' $'m' $'n' $'\u014B' $'\u014B\u02B7' $'m\u0325' $'n\u0325' $'\u014B\u0325' $'\u014B\u0325\u02B7' $'i' $'u' $'\u0259' $'a')

declare -A CSYIPA
for i in "${!CSYchars[@]}"; do
	if [ -n "${CSYchars[$i]}" ]; then
		CSYIPA["${CSYchars[$i]}"]="${IPAchars[$i]}"
	fi
done

declare -A doublerMap
doublerMap["l"]="ll"
doublerMap["r"]="rr"
doublerMap["g"]="gg"
doublerMap["gh"]="ghh"
doublerMap["ghw"]="ghhw"
doublerMap["m"]="mm"
doublerMap["n"]="nn"
doublerMap["ng"]="ngng"
doublerMap["ngw"]="ngngw"

declare -A isVoiceless
for char in p t k kw q qw f s wh; do
	isVoiceless[$char]=1
done

declare -A isVoicelessDoubled
for char in rr gg ghh ghhw mm nn ngng ngngw ll; do
	isVoicelessDoubled[$char]=1
done

sortedTokens=$(for key in "${!CSYIPA[@]}"; do echo "${#key} $key"; done | sort -rn | awk '{print $2}')
readarray -t tokenSearchOrder <<< "$sortedTokens"

function tokenizeWord() {
	local tempWord="$1"
	local -n tokensRef=$2
	
	while [ -n "$tempWord" ]; do
		local foundToken=false
		
		for token in "${tokenSearchOrder[@]}"; do
			if [[ "${tempWord,,}" == "${token}"* ]]; then
				tokensRef+=("$token")
				tempWord="${tempWord:${#token}}"
				foundToken=true
				break
			fi
		done
		
		if ! $foundToken; then
			tokensRef+=("${tempWord:0:1}")
			tempWord="${tempWord:1}"
		fi
	done
}

function transDoubling() {
	local -n inputTokens=$1
	local length=${#inputTokens[@]}
	
	for ((i=0; i<length; i++)); do
		local currSound="${inputTokens[$i]}"
		local prevSound=""
		local nextSound=""
		local doubledSound="${doublerMap[$currSound]}"
		local shouldDouble=false
		
		if [[ -z "$doubledSound" ]]; then
			continue
		fi

		if [[ $i -gt 0 ]]; then
			prevSound="${inputTokens[$((i-1))]}"
		fi
		if [[ $i -lt $((length-1)) ]]; then
			nextSound="${inputTokens[$((i+1))]}"
		fi

		if [[ "$currSound" =~ ^(l|r|g|gh|ghw)$ ]]; then # Double if next sound is voiceless
			if [[ -n "${isVoiceless[$nextSound]}" ]] || \
			   [[ "$nextSound" == "ll" ]] || \
			   [[ -n "${isVoicelessDoubled[$prevSound]}" ]]; then
				shouldDouble=true
			fi
		elif [[ "$currSound" =~ ^(m|n|ng|ngw)$ ]]; then
			if [[ -n "${isVoiceless[$prevSound]}" ]] || \
			   [[ "$nextSound" == "ll" ]] || \
			   [[ -n "${isVoicelessDoubled[$prevSound]}" ]]; then
				shouldDouble=true
			fi
		fi

		if $shouldDouble; then
			inputTokens[$i]="$doubledSound"
			if  [[ ! "$currSound" == "$doubledSound" ]] ; then
				echo "Doubled $currSound -> $doubledSound on Line $lineNum." >&2;
			fi
		fi
	done
}

function convertIPA() {
	local -n tokensToConvert=$1
	local result=""

	for token in "${tokensToConvert[@]}"; do
		if [[ -n "${CSYIPA[$token]}" ]]; then
			local IPAchar="${CSYIPA[$token]}"
			result+="$IPAchar"
			if [[ ! "$token" == "$IPAchar" ]] ; then
				echo "Converted $token -> $IPAchar on Line $lineNum." >&2;
			fi
		else
			result+="$token"
		fi
	done
	echo "$result"
}

function joinTokens() {
	local -n tokensToJoin=$1
	local result=""
	for token in "${tokensToJoin[@]}"; do
		result+="$token"
	done
	echo "$result"
}

if [[ "$#" -lt 1 ]] || [[ "$#" -gt 2 ]] ; then
	echo "Function: Enforces transparent orthography for Central Siberian Yupik files with undoubling and IPA."
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

transparentFile="${outputFile}.tmp"
> "$transparentFile"


lineNum=0
while IFS= read -r line || [[ -n "$line" ]]; do
	((lineNum++))
	fixedLine=""
	for word in $line; do
		tokens=()
		tokenizeWord "$word" tokens # Split line into tokens
		transDoubling tokens # Double Yupik chars/graphemes where applicable
		joinedWord=$(joinTokens tokens)
		fixedLine+="$joinedWord "
	done
	echo "${fixedLine% }" >> "$transparentFile" # Temp. file before IPA conversion
done < "$outputFile"

echo ""

lineNum=0
> "$outputFile"
while IFS= read -r line || [[ -n "$line" ]]; do
	((lineNum++))
	convertedLine=""
	for word in $line; do
		tokens=()
		tokenizeWord "$word" tokens
		converted=$(convertIPA tokens) # Replace CSYchars with IPAchars in tokens
		convertedLine+="$converted "
	done
	echo "${convertedLine% }" >> "$outputFile"
done < "$transparentFile"

rm "$transparentFile"

echo -e "\nDone. Check for transparent orthography in $outputFile."
exit 0
