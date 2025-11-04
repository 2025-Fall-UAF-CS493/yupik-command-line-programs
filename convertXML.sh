#!/bin/bash

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 [Input File] [Output File (Optional)]"
    echo "Example: $0 sampleFormatted.txt output.xml"
    exit 1
fi

inputFile="$1"
outputFile=""

if [ "$#" -eq 2 ]; then
    outputFile="$2"
else
    outputFile="${inputFile%.txt}.xml"
fi

if [ ! -f "$inputFile" ]; then
    echo "Error: Input file '$inputFile' not found."
    exit 1
fi

echo "Converting '$inputFile' to '$outputFile'..."

echo '<root>' > "$outputFile"

while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then
        continue
    fi

    if [[ "$line" =~ ^[0-9]+$ ]]; then
        echo "  <pageNum>$line</pageNum>" >> "$outputFile"
        continue
    fi
    
    if ! [[ "$line" =~ ^[A-Z]+ ]]; then
        continue
    fi

    echo "  <entry>" >> "$outputFile"

    langTag=$(echo "$line" | sed -E 's/^([A-Z]+).*/\1/') #langTags should already be at beginning of line from fixFormatting.sh
    echo "    <langTag>$langTag</langTag>" >> "$outputFile"
    content=$(echo "$line" | sed -E "s/^${langTag}\s*//")

    nativePart=""
    engPart=""
    notePart=""

    if [[ "$content" == *‘*’* ]]; then
        nativePart=$(echo "$content" | sed -E "s/^(.*?)‘.*$/\1/")
        engPart=$(echo "$content" | sed -E "s/^.*?‘([^’]*)’.*/\1/")
        notePart=$(echo "$content" | sed -E "s/^.*?‘[^’]*’(.*)$/\1/")
    else
        nativePart="$content"
    fi

    nativePart=$(echo "$nativePart" | sed -E 's/^[ \t]+|[ \t]+$//g')
    engPart=$(echo "$engPart" | sed -E 's/^[ \t]+|[ \t]+$//g')
    notePart=$(echo "$notePart" | sed -E 's/^[ \t]+|[ \t]+$//g')

    nativePart=$(echo "$nativePart" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    engPart=$(echo "$engPart" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    notePart=$(echo "$notePart" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')

    echo "    <nativeWord>$nativePart</nativeWord>" >> "$outputFile"
    echo "    <engWord>$engPart</engWord>" >> "$outputFile"
    echo "    <note>$notePart</note>" >> "$outputFile"

    echo "  </entry>" >> "$outputFile"

done < "$inputFile"

echo '</root>' >> "$outputFile"

echo "Finished conversion: '$outputFile' created."
exit 0

