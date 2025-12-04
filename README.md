Command-line programs for CS F493: Language Reclamation & Technology on St. Lawrence Island; Fall 2025 class at the University of Alaska Fairbanks. By Ian Rodriguez.<br>

*Parameters with an asterisk are optional.

**-PROGRAMS-**<br>
*Find-and-Replace.sh*<br>
**Function**: Basic Find and Replace with sed command for a given file.<br>
**How to use**: ./Find-and-Replace.sh [searchStr] [replaceStr] [inputFile] [outputFile*]<br>
**How it works**: Basic sed command that replaces your first parameter with your second parameter throughout your file; no Regex.<br>
**Notes**: Used in yupikCorrector.sh. Needs to be in current directory for that program to function. If outputFile is not entered, then inputFile will be modified in-place.<br>

*yupikCorrector.sh*<br>
**Function**: Spell-checker for Central Siberian Yupik files. Prompts user to modify each potential error found by the program.<br>
**How to use**: ./yupikCorrector.sh [inputFile]<br>
**How it works**: Reads line-by-line then tokenizes words, then checks if the words have errors in voicing (no voiced consonants next to unvoiced) or structure (C V C format).
Calls promptFix for each instance it finds, allowing user to call Find-and-Replace on entire file or Regex for specific instance. Also tells how many errors it found.<br>
**Notes**: Find-and-Replace.sh needs to be in current directory for the program to function.<br>

*corpusStats.sh*<br>
**Function**: Prints out corpus stats for a given file. Gives character/grapheme frequency, line count, word count, character count, and average word length.<br>
**How to use**: ./corpusStats.sh [inputFile] [EN/CSY*]<br>
**How it works**: Uses built-in Bash command tools like cat and wc to tell stats about a file. Also counts every instance of each character/grapheme/word in the file and calculates frequency.<br>
**Notes**: Defaults to English when used. Have to specify CSY, ESS, or Yupik at the end of each command.<br>

*fixFormatting.sh*<br>
**Function**: Formats Central Siberian Yupik documents with font symbols.<br>
**How to use**: ./fixFormatting.sh [inputFile] [outputFile*] [CSY/CAY/IPA/APA*]<br>
**How it works**: User is given option 1 or option 2: The first formats the file into columns, then replaces font symbols. The latter skips the first step and just replaces the font symbols.
For Option 1, it puts the file on a single line, then newlines after every language tag (PE, NSY, etc). Then, it uses awk to break the lines into Yupik entries, notes, etc. based on punctuation.
For Option 2 (or after Option 1 is done formatting), it prompts the user which columns of the file to replace font symbols in, makes a temp file of each column, and uses sed to replace every
instance of font symbols with the designated cleanup array type (CSY/CAY/IPA/APA). It has a duplicate file of potential risky replacements from the sed that don't end in dashes, q's, or have
numbers as font symbols instead of letters. It then runs a second repair sed that replaces all the likely English back to its original self from the temp file.<br>
**Notes**: If outputFile isn't entered, then inputFile will be modified in-place. If symbol cleanup type isn't entered, then it defaults to CSY (Central Siberian Yupik Latin orthography).<br>

*transOrthography.sh*<br>
**Function**: Enforces transparent orthography for Central Siberian Yupik files with undoubling and IPA.<br>
**How to use**: ./transOrthography.sh [inputFile] [outputFile*]<br>
**How it works**: Maps out an associative array between Central Siberian Yupik Latin orthography and IPA symbols, as well as between undoubled and doubled variants of Yupik letters/graphemes. It reads through the input file line-by-line, tokenizes it into words, then enforces transparent orthography through function transDoubling, which checks if the next/previous sound in each token is voiced or unvoiced and doubles accordingly. Next, it calls convertIPA function to use the associative array and replace each sound with IPA where applicable. Each line is written to the output file, and the user is alerted of all the changes in the Shell.<br>
