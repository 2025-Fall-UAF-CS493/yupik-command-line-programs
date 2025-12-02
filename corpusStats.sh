#!/bin/bash

function instancesPlural() { # Grammar
	local compareVar=$1
	if [[ "$compareVar" -eq 1 ]] ; then
		echo "instance"
	else
		echo "instances"
	fi
}

if [[ "$#" -eq 1 ]] ; then
	langInput="EN"
	echo "Using English as default..."
elif [[ "$#" -eq 2 ]]; then
	langInput="$2"

	case ${langInput^^} in
		ESS|CSY|YUPIK)
			echo "You chose Yupik!"
			langInput="ESS"
			;;
		EN|ENGLISH)
			echo "You chose English!"
			langInput="EN"
			;;
		*)
			echo "Language not recognized. Defaulting to English..."
			langInput="EN"
			;;
	esac
else
	echo "Current function: Prints out corpus stats for a given file."
	echo "How to use $0: [Function] [inputFile] [EN/CSY (Optional, defaults to English)]"
	exit 0
fi

declare -a yupInstanceList
declare -a englishAlphabet=({a..z})
yupikAlphabet=('ngngw' 'ngng' 'ghhw' 'ghw' 'ghh' 'ngw' 'ng' 'nn' 'mm' 'gg' 'gh' 'll' 'rr' 'wh' 'aa' 'ii' 'uu' 'g' 'l' 'r' 'v' 'z' 'w' 'm' 'n' 'f' 's' 'p' 't' 'k' 'q' 'e' 'a' 'i' 'u') # Including multi-char graphemes

inputFile="$1"
lineCount=$(wc -l < "$inputFile")
wordCount=$(wc -w < "$inputFile")
charCount=$(wc -c < "$inputFile")
wordFreq=$(cat "$inputFile" | tr -cs '[:alpha:]' '\n' | tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -nr | head -10)

altFile=$(tr '[:upper:]' '[:lower:]' < "$inputFile")

if [[ "$langInput" == "ESS" ]]; then
    echo "Character and grapheme frequency in $inputFile:"
    
    declare -a yupInstanceList
    totalGraphemeCount=0

    for i in {0..34}; do
        currLetter=${yupikAlphabet[i]}
        currLetterCount=$(grep -o "$currLetter" <<< "$altFile" | wc -l)
        yupInstanceList[$i]=$currLetterCount
        totalGraphemeCount=$((totalGraphemeCount + currLetterCount))
        if [[ $currLetterCount -gt 0 ]]; then
            altFile=$(sed "s/$currLetter/ /g" <<< "$altFile")
        fi
    done

    declare -a zeroChars=() 
    numNoChars=0
    for i in {0..34}; do
        currLetter=${yupikAlphabet[i]}
        currLetterCount=${yupInstanceList[$i]}
        if [[ "$currLetterCount" -gt 0 ]] ; then
            if [[ "$totalGraphemeCount" -gt 0 ]]; then
                charFreqPercent=$(echo "scale=2; $currLetterCount * 100 / $totalGraphemeCount" | bc)
                echo "$currLetter: $currLetterCount $(instancesPlural $currLetterCount), $charFreqPercent% frequency in file"
            else
                echo "$currLetter: $currLetterCount $(instancesPlural $currLetterCount) (no graphemes found)"
            fi
        else
            zeroChars+=("$currLetter")
            numNoChars=$((numNoChars + 1))
        fi
    done

    if [[ $numNoChars -gt 0 ]]; then
        noCharMessage="Zero instances of "
        for j in "${!zeroChars[@]}"; do
            noCharMessage+="${zeroChars[j]}"
            if [[ $j -lt $((numNoChars - 1)) ]]; then
                noCharMessage+=", "
            fi
            if (( (j + 1) % 20 == 0 )); then
                noCharMessage+="\n"
            fi
        done
        echo -e "\n$noCharMessage"
    fi

    maxCount=0
    maxLetter=""
    for i in {0..34}; do
        if [[ ${yupInstanceList[i]} -gt $maxCount ]]; then
            maxCount=${yupInstanceList[i]}
            maxLetter=${yupikAlphabet[i]}
        fi
    done
    echo -e "\nMost common Yupik character: $maxLetter ($maxCount $(instancesPlural $maxCount))"

else
    echo "Character frequency in $inputFile:"
    
    declare -a englishInstanceList
    totalLetterCount=0

    for i in {0..25}; do
        currLetter=${englishAlphabet[i]}
        currLetterCount=$(grep -o "$currLetter" <<< "$altFile" | wc -l) # Avoiding repeats in char count
        englishInstanceList[$i]=$currLetterCount
        totalLetterCount=$((totalLetterCount + currLetterCount))
    done

    declare -a zeroChars=() # Array of English letters / Yupik graphemes that don't show up in inputFile 
    numNoChars=0
    for i in {0..25}; do
        currLetter=${englishAlphabet[i]}
        currLetterCount=${englishInstanceList[i]}
        if [[ "$currLetterCount" -gt 0 ]] ; then
            if [[ "$totalLetterCount" -gt 0 ]]; then
                charFreqPercent=$(echo "scale=2; $currLetterCount * 100 / $totalLetterCount" | bc)
                echo "$currLetter: $currLetterCount $(instancesPlural $currLetterCount), $charFreqPercent% frequency in file"
            else
                echo "$currLetter: $currLetterCount $(instancesPlural $currLetterCount) (no letters found)"
            fi
        else
            zeroChars+=("$currLetter")
            numNoChars=$((numNoChars + 1))
        fi
    done

    if [[ $numNoChars -gt 0 ]]; then
        noCharMessage="Zero instances of "
        for j in "${!zeroChars[@]}"; do
            noCharMessage+="${zeroChars[j]}"
            if [[ $j -lt $((numNoChars - 1)) ]]; then
                noCharMessage+=", "
            fi
            if (( (j + 1) % 20 == 0 )); then # Formatting test
                noCharMessage+="\n"
            fi
        done
        echo -e "\n$noCharMessage"
    fi

    maxCount=0
    maxLetter=""
    for i in {0..25}; do
        if [[ ${englishInstanceList[i]} -gt $maxCount ]]; then
            maxCount=${englishInstanceList[i]}
            maxLetter=${englishAlphabet[i]}
        fi
    done
    echo -e "\nMost common English character: $maxLetter ($maxCount $(instancesPlural $maxCount))"

fi

longestWord=$(cat "$inputFile" | tr -cs '[:alpha:]' '\n' | grep -v '^\s*$' | awk '{print length, $0}' | sort -nr | head -1 | awk '{print $2}')
allWordsLength=$(cat "$inputFile" | tr -cs '[:alpha:]' '\n' | tr -d '\n' | wc -c)

if [[ "$wordCount" -gt 0 ]] ; then
	avgWordLength=$(echo "scale=2; $allWordsLength / $wordCount" | bc)
else
	avgWordLength="0"
fi


echo -e "\nLine count of $inputFile: $lineCount"
echo "Word count of $inputFile: $wordCount"
echo "Character count of $inputFile: $charCount"
echo -e "\nWord frequency in $inputFile:\n$wordFreq"

mostCommonWordLine=$(echo "$wordFreq" | head -n 1 | awk '{$1=$1;print}')
mostCommonWord=$(echo "$mostCommonWordLine" | awk '{print $2}')
mostCommonWordCount=$(echo "$mostCommonWordLine" | awk '{print $1}')


echo -e "\nMost common word in $inputFile: $mostCommonWord ($mostCommonWordCount $(instancesPlural $mostCommonWordCount))"
echo "Longest word (total characters) in $inputFile: $longestWord (${#longestWord} chars)"
echo -e "Average word length in $inputFile: $avgWordLength chars\n"

exit 0
