#!/bin/bash

# Abbreviations for Native languages.
abbrvNL=("PI" "SPI" "NAI" "WCI" "GRI" "ECI" "PI" "CSY" "AAY" "CAY" "NSY" "NWI" "PE" "PWS") 

fontSymbols=("p" "t" "k" "kw" "q" "qw" "v" "l" "z" "y" "$" "!" "!w" "3" "3w" "f" "@" "s" "5" "x" "xw" "X" "Xw" "h" "m" "n" "&" "&w" "6" "%" "7" "7w" "i" "u" "0" "a" "4" "9" "\\")

CAYReplacements=("p" "t" "k" "" "q" "" "v" "l" "s" "y" "" "g" "ug" "r" "" "vv" "ll" "ss" "" "gg" "w" "rr" "" "h" "m" "n" "ng" "" "ḿ" "ń" "ńg" "" "i" "u" "e" "a" "" "" "")
CSYReplacements=("p" "t" "k" "kw" "q" "qw" "v" "l" "z" "y" "r" "g" "w" "gh" "ghw" "f" "ll" "s" "rr" "gg" "w" "gh" "ghw" "h" "m" "n" "ng" "ngw" "ḿ" "ń" "ńg" "ńgw" "i" "u" "e" "a" "" "" "")
APAReplacements=("p" "t" "k" "kʷ" "q" "qʷ" "v" "l" "z" "y" "ž" "ɣ" "ɣʷ" "ʀ" "ʀʷ" "f" "ł" "s" "š" "x" "xʷ" "X" "Xʷ" "h" "m" "n" "ŋ" "ŋʷ" "m̥" "n̥" "ŋ̥" "ŋ̥ʷ" "i" "u" "ə" "a" "ɨ" "ð" "R̃")
IPAReplacements=($'p' $'t' $'k' $'k\u02B7' $'q' $'q\u02B7' $'v' $'l' $'z' $'j' $'\u0290' $'\u0263' $'\u0263\u02B7' $'\u0281' $'\u0281\u02B7' $'f' $'\u026C' $'s' $'\u0282' $'x' $'x\u02B7' $'\u03C7' $'X\u02B7' $'h' $'m' $'n' $'\u014B' $'\u014B\u02B7' $'m\u0325' $'n\u0325' $'\u014B\u0325' $'\u014B\u0325\u02B7' $'i' $'u' $'\u0259' $'a' $'\u0268' $'\u00F0' $'\u0274')
# Index 7: The APA->IPA file from ling. group has 'l' with theta as its unicode. Leaving this here until I can clarify
# Index 35: The APA->IPA file from ling. group has 'a' with an umlaut in its unicode. Same situation.
# Index 12: The APA->IPA file from ling. group has 'ligature' after 'ug', but this can mess up text when replacing.

function replaceSymbolsInColumn() {
	local inputFile="$1"
	local columnNumber="$2"
	local replacementArrayName="$3"
	declare -n cleanupArray="$replacementArrayName"

	echo "Processing Column $columnNumber with $replacementArrayName..."

	if [ ${#cleanupArray[@]} -eq 0 ]; then
		echo "Error: Replacement array '$replacementArrayName' is empty." >&2; return 1
    	fi

	# Sort by longest font symbols first
	local sortedIndices=$(for i in "${!fontSymbols[@]}"; do [ -n "${fontSymbols[$i]}" ] && echo "${#fontSymbols[$i]} $i"; done | sort -rn | awk '{print $2}')

	local numCols=$(awk -F'\t' '{if(NF>max) max=NF} END {print max}' "$inputFile")
    
	local pasteArgs=""
	local tempCols=()

	for ((i=1; i<=numCols; i++)); do
        	cut -f"$i" "$inputFile" > "$inputFile.col$i.tmp"
        	tempCols+=("$inputFile.col$i.tmp")
        	pasteArgs="$pasteArgs $inputFile.col$i.tmp"
    	done

	local targetFile="$inputFile.col$columnNumber.tmp"

	if [ ! -f "$targetFile" ]; then
		echo "Error: Column $columnNumber does not exist in this file. Skipping..."
		rm "${tempCols[@]}" 2>/dev/null
        	return 1
	fi

	riskyChars="" 
	riskyMap=""
	local repairSed="$inputFile.repair.sed"
	> "$repairSed"
	
	declare -A seenWords

	for i in "${!fontSymbols[@]}"; do
		foundChar="${fontSymbols[$i]}"
		replaceChar="${cleanupArray[$i]}"
		
		if [[ "$foundChar" =~ ^[a-zA-Z]$ ]] && [[ "$foundChar" != "$replaceChar" ]]; then
			riskyChars="${riskyChars}${foundChar}"
			riskyMap="${riskyMap}${foundChar}=${replaceChar},"
		fi
	done

	if [ -n "$riskyChars" ]; then
		declare -A bashReplMap
		IFS=',' read -ra mapPairs <<< "$riskyMap"
		for pair in "${mapPairs[@]}"; do
			if [[ "$pair" == *"="* ]]; then
				key="${pair%%=*}"
				val="${pair##*=}"
				bashReplMap[$key]="$val"
			fi
		done

		while IFS= read -r line || [[ -n "$line" ]]; do
			for word in $line; do
				wordNoPunct="${word//[^a-zA-Z-]/}" 

				if [[ "$wordNoPunct" =~ [$riskyChars] ]] && \
				   [[ "$wordNoPunct" =~ ^[a-zA-Z-]+$ ]]; then
					
					if [[ "$word" == *- ]]; then continue; fi

					if [[ "$word" =~ [qQ]$ ]] || [[ "$word" =~ [qQ][[:punct:]]$ ]]; then
						if ! [[ "$wordNoPunct" =~ ^(FAQ|IQ|tranq)$ ]]; then
							continue
						fi
					fi

					if [[ -n "${seenWords[$wordNoPunct]}" ]]; then continue; fi
					seenWords[$wordNoPunct]=1

					corruptedCore="$wordNoPunct"
					for char in "${!bashReplMap[@]}"; do
						if [[ "$wordNoPunct" == *"$char"* ]]; then
							corruptedCore="${corruptedCore//$char/${bashReplMap[$char]}}"
						fi
					done

					echo "s/\\b$corruptedCore\\b/$wordNoPunct/g" >> "$repairSed"
				fi
			done
		done < "$targetFile"
	fi

	for i in $sortedIndices; do
        	local preSymbols=$(sed -e 's/[$\\]/\\&/g' <<<"${fontSymbols[i]}")
        	local postSymbols="${cleanupArray[i]}"
        	postSymbols=$(sed -e 's/[&\\/]/\\&/g' <<<"$postSymbols")

        	sed -i -E "s#$preSymbols#$postSymbols#g" "$targetFile" # Replace current fontSymbols with respective replacement by index
    	done

	if [ -s "$repairSed" ]; then
		sed -i -E -f "$repairSed" "$targetFile"
		rm "$repairSed"
	else
		rm "$repairSed" 2>/dev/null
	fi

	paste $pasteArgs > "$inputFile"
	rm "${tempCols[@]}" 2>/dev/null
}

function optionPrompt() {
	local fileToProcess="$1"
	local arrayToUse="$2"

	echo "Which columns would you like font symbols replaced in?"
	echo "Enter column number(s); use spaces if multiple: "
	read -p "Columns: " inputCols

	for col in $inputCols; do
		replaceSymbolsInColumn "$fileToProcess" "$col" "$arrayToUse"
    done
}

inputFile="$1"

if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
	echo "Usage: $0 [Input File] [Output File] [Cleanup Format (CSY/CAY/APA/IPA)]"
	echo "Or: [Input File] [Cleanup Format]; edits input file in-place."
	echo "Or: just [Input File]; edits input file in-place with defualt CSY cleanup format."
	echo "Use -t as only parameter to test symbol array sizes."
    	exit 1
fi

if [ "$1" == "-t" ]; then
	size0=${#fontSymbols[@]}; size1=${#CAYReplacements[@]}; size2=${#CSYReplacements[@]}; size3=${#APAReplacements[@]}; size4=${#IPAReplacements[@]}
    	echo -e "Array Sizes:\nFont Symbols: $size0\nCAY: $size1\nCSY: $size1\nAPA: $size3\nIPA: $size4"
	exit 0
fi

cleanupTypeInput=""

if [ "$#" -eq 1 ]; then # For just inputting a file with no output file or cleanup type
	outputFile="$inputFile"
	cleanupTypeInput="CSY"
	echo "Defaulting to CSY..."
elif [ "$#" -eq 2 ]; then
	secondParameter="$2"
	case ${secondParameter^^} in
		(IPA|APA|CSY|ESS|CAY) # For inputting a file and a cleanup type, but no other output file
			cleanupTypeInput="$2"
			outputFile="$inputFile"
			;;
		*)
			cleanupTypeInput="CSY"
			outputFile="$2"
			echo "Defaulting to CSY..."
			;;
	esac
elif [ "$#" -eq 3 ]; then # Proper parameters: input file, output file, and cleanup type
	outputFile="$2"
	cleanupTypeInput="$3"
fi

case ${cleanupTypeInput^^} in
	IPA)
    		arrayName="IPAReplacements"
		;;
	APA)
		arrayName="APAReplacements"
		;;
	CAY)
		arrayName="CAYReplacements"
		;;
	CSY|ESS)
		arrayName="CSYReplacements"
		;;
    	*)
		arrayName="CSYReplacements"
		if [ "$cleanupTypeInput" != "CSY" ]; then
			echo "Defaulting to CSY..."
		fi
		;;
esac

echo "Option 1: Reformat all of $inputFile into columns, then replace font symbols."
echo "Option 2: Replace font symbols in specified columns of ALREADY formatted $inputFile."
read -p "Enter option (1/2): " formatOption


if [[ "$formatOption" -eq 2 ]] ; then
	if [ "$inputFile" != "$outputFile" ]; then
        	cp "$inputFile" "$outputFile"
    	fi

	optionPrompt "$outputFile" "$arrayName"

	echo "Done! Check $outputFile"
	exit 0

elif [[ "$formatOption" -lt 1 ]] || [[ "$formatOption" -gt 2 ]]; then
	echo "Invalid option."
	exit 1
fi

# Everything from here on out is only if Option 1 is chosen.
tempFile="$inputFile.tmp"
cp "$inputFile" "$tempFile"
tr -d '\n' < "$tempFile" > "$outputFile"
rm "$tempFile"

sed -i -E "s/([0-9]+)([A-Z]{2,3}\b)/\1\n\2/g" "$outputFile"
for langTag in "${abbrvNL[@]}"; do
	sed -i -E "s/\b($langTag)\b/\n\1/g" "$outputFile"; # Newline after each langTang
done 

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

echo "Applying symbol replacement..."
optionPrompt "$outputFile" "$arrayName"

exit 0
