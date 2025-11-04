#!/bin/bash

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
	echo "How to use: $0 'searchStr' 'replaceStr' 'inputFile' 'outputFile'" # outputFile is optional.
	echo "outputFile is optional; if not used, will rewrite inputFile"
	exit 1
fi

searchStr="$1"
replaceStr="$2"
inputFile="$3"

if [ "$#" -eq 4 ]; then
	outputFile="$4"
	if [ "$outputFile" == "$inputFile" ]; then
		echo "Error: Input and output files can\'t be the same."
		echo "If you want to modify a file w/o copies, only use the first three arguments."
		exit 1
	fi


	sed "s/${searchStr}/${replaceStr}/g" "${inputFile}" > "${outputFile}"
	cat "${outputFile}"
else
	sed -i "s/${searchStr}/${replaceStr}/g" "${inputFile}"
fi
exit 0

