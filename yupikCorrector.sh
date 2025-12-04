#!/bin/bash

findReplaceFile="./Find-and-Replace.sh"
lingErrors=0

# In St. Lawrence Island Yupik, a voiced consonant can't be next to a voiceless one.

# Voiced Continuants (Fricatives, Laterals, Nasals): g, gh, l, r, v, z, w, m, n, ng, (ghw, ngw)
# Voiceless Continuants (Fricatives, Laterals, Nasals): gg, ghh, ll, rr, f, s, (wh), mm, nn, ngng, (ghhw, ngngw)
# Voiceless Stops (which often cause the change): p, t, k, q

voicingPairs=(
	# g -> gg
	"gt:ggt" "gk:ggk" "gq:ggq" "gs:ggs" "gp:ggp" "gf:ggf"
	# gg -> g
	"gga:ga" "ggi:gi" "ggu:gu" "gge:ge"
	# ghh -> gh
	"ghha:gha" "ghhi:ghi" "ghhu:ghu" "ghhe:ghe"
	# gh -> ghh
	"ght:ghht" "ghk:ghhk" "ghq:ghhq" "ghs:ghhs" "ghp:ghhp" "ghf:ghhf"
	# l -> ll
	"lt:llt" "lk:llk" "lq:llq" "ls:lls" "lp:llp" "lf:llf"
	# r -> rr
	"rt:rrt" "rk:rrk" "rq:rrq" "rs:rrs" "rp:rrp" "rf:rrf"
	# v -> f
	"vt:ft" "vk:fk" "vq:fq" "vs:fs" "vp:fp" "vf:ff"
	# z -> s
	"zt:st" "zk:sk" "zq:sq" "zs:ss" "zp:sp" "zf:sf"
	# w -> wh
	"wt:wht" "wk:whk" "wq:whq" "ws:whs" "wp:whp" "wf:whf"
	# m -> mm
	"mt:mmt" "mk:mmk" "mq:mmq" "ms:mms" "mp:mmp" "mf:mmf"
	# n -> nn
	"nt:nnt" "nk:nnk" "nq:nnq" "ns:nns" "np:nnp" "nf:nnf"
	# ng -> ngng
	"ngt:ngngt" "ngk:ngngk" "ngq:ngngq" "ngs:ngngs" "ngp:ngngp" "ngf:ngngf"
	# ghw -> ghhw
	"ghwt:ghhwt" "ghwk:ghhwk" "ghwq:ghhwq" "ghws:ghhws" "ghwp:ghhwp" "ghwf:ghhwf"
	# ngw -> ngngw
	"ngwt:ngngwt" "ngwk:ngngwk" "ngwq:ngngwq" "ngws:ngngws" "ngwp:ngngwp" "ngwf:ngngwf"
)

# Longest first for comparison
yupikAlphabet=('ngngw' 'ngng' 'ghhw' 'ghw' 'ghh' 'ngw' 'ng' 'nn' 'mm' 'gg' 'gh' 'll' 'rr' 'wh' 'aa' 'ii' 'uu' 'g' 'l' 'r' 'v' 'z' 'w' 'm' 'n' 'f' 's' 'p' 't' 'k' 'q' 'e' 'a' 'i' 'u')
yupikVowels="^(aa|ii|uu|a|i|u|e|AA|II|UU|A|I|U|E|Aa|Ii|Uu)$"

promptFix() { # Prompts user to fix CSY errors after finding them
	local errorType="$1"
	local currentWord="$2"
	local suggestion="$3"
	local lineNumber="$4"
	local searchPattern="$5" # Full word

	echo -e "\n[Error] $errorType (Line $lineNumber)"
	echo -e "\tWord:\t$currentWord"
	if [ -n "$suggestion" ]; then
		echo -e "\tFix:\t'$suggestion' (Detected)"
	else
		echo -e "\tFix:\t[Manual Input Required]"
	fi

	read -p "  Would you like to fix this? (Y/N): " doFix < /dev/tty

	if [[ "$doFix" =~ ^[Yy]$ ]]; then
		local finalReplacement=""

		if [ -n "$suggestion" ]; then
			read -p "  Use suggestion '$suggestion'? (Hit enter for yes, type new word to override): " userOverride < /dev/tty
			if [ -n "$userOverride" ]; then
				finalReplacement="$userOverride"
			else
				finalReplacement="$suggestion"
			fi
		else
			read -p "  Enter the corrected word: " finalReplacement < /dev/tty
		fi

		if [ -n "$finalReplacement" ]; then
			echo -e "\t1) Fix this instance ONLY (Line $lineNumber)\n\t2) Fix GLOBALLY (Entire file)"
			read -p "  Choose option (1/2): " scope < /dev/tty

			if [ "$scope" == "1" ]; then
				# Use sed to replace only on the specific line
				sed -i "${lineNumber}s|${searchPattern}|${finalReplacement}|" "$inputFile"
				echo -e "\t[Success] Fixed on line $lineNumber."

				# Update the variable in memory so subsequent checks for this word don't fire
				word="${word//$searchPattern/$finalReplacement}"

			elif [ "$scope" == "2" ]; then
				"$findReplaceFile" "$searchPattern" "$finalReplacement" "$inputFile"
				echo -e "\t[Success] Fixed globally."

				appliedRules["$searchPattern"]=1 # No prompting after this
				 word="${word//$searchPattern/$finalReplacement}"
			else
				echo -e "\tCancelled."
			fi
		fi
	else
		echo -e "\tSkipped."
	fi
}


if [ "$#" -ne 1 ]; then
	echo "Function: Spell-checker for Central Siberian Yupik. Prompts user to modify each potential error found by the program."
	echo "Usage: $0 [inputFile]"
	exit 1
fi

inputFile="$1"

if [ ! -f "$inputFile" ]; then
	echo "Error: Input file not found: $inputFile"
	exit 1
fi

fileContent=$(cat "$inputFile") # Read into variable to prevent loop from breaking

echo "Checking $inputFile for linguistic/spelling errors..."

lineNumber=0
declare -A appliedRules


while IFS= read -r line; do
	lineNumber=$((lineNumber + 1))

	for word in $line; do
		originalWord="$word"

		# Voicing Harmony Checks
		for rule in "${voicingPairs[@]}"; do
			searchString=$(echo "$rule" | cut -d':' -f1)
			replaceString=$(echo "$rule" | cut -d':' -f2)

			if [[ "$word" == *"$searchString"* ]] && [[ -z "${appliedRules[$searchString]}" ]]; then
				((lingErrors++))
				promptFix "Voicing Harmony Error" "$word" "$replaceString" "$lineNumber" "$searchString"
			fi
		done

		# Tokenize words to check for (C) V (C) format
		tempWord="$word"
		tokenList=()
		while [ -n "$tempWord" ]; do
			foundToken=false
			for token in "${yupikAlphabet[@]}"; do
				if [[ "${tempWord,,}" == $token* ]]; then
					tokenList+=("${tempWord:0:${#token}}")
					tempWord="${tempWord:${#token}}"
					foundToken=true
					break
				fi
			done
			if ! $foundToken; then
				unknownChar="${tempWord:0:1}"
				[ -n "$unknownChar" ] && tokenList+=("$unknownChar")
				tempWord="${tempWord:1}"
			fi
		done

		syllableStructure=""
		for token in "${tokenList[@]}"; do
			if [[ "$token" =~ $yupikVowels ]]; then
				syllableStructure+="V"
			else
				isConsonant=false
				tokenLower="${token,,}"
				for symbol in "${yupikAlphabet[@]}"; do
					[[ "$tokenLower" == "$symbol" ]] && isConsonant=true && break
				done
				$isConsonant && syllableStructure+="C"
			fi
		done
		
		if [[ "$syllableStructure" != *"V"* ]] && [ -n "$syllableStructure" ]; then
			 ((lingErrors++))
			 promptFix "Missing Vowel (Syllable Violation)" "$word" "" "$lineNumber" "$word"
		fi

		if [[ "$syllableStructure" == CC* ]]; then
			((lingErrors++))
			promptFix "Invalid Cluster (Starts with CC)" "$word" "" "$lineNumber" "$word"
		fi

		if [[ "$syllableStructure" == *CC ]]; then
			((lingErrors++))
			promptFix "Invalid Cluster (Ends with CC)" "$word" "" "$lineNumber" "$word"
		fi

		if [[ "$syllableStructure" == *CCC* ]]; then
			((lingErrors++))
			promptFix "Invalid Cluster (3+ Consonants)" "$word" "" "$lineNumber" "$word"
		fi

	done
done <<< "$fileContent"

if [[ lingErrors -eq 1 ]]; then
	errorsPlural="error"
else
	errorsPlural="errors"
fi

echo -e "\nEnd of spellcheck. $lingErrors spelling/linguistic $errorsPlural found.\n"

exit 0
