Command-line programs for CS F493: Language Reclamation & Technology on St. Lawrence Island; Fall 2025 class at the University of Alaska Fairbanks.

*Parameters with an asterisk are optional.

**-PROGRAMS-**
*Find-and-Replace.sh*
Function: Basic Find and Replace with sed command for a given file.
How to use: ./Find-and-Replace.sh [searchStr] [replaceStr] [inputFile] [outputFile*]
How it works: Basic sed command that replaces your first parameter with your second parameter throughout your file; no Regex.
Notes: Used in yupikCorrector.sh. Needs to be in current directory for that program to function. If outputFile is not entered, then inputFile will be modified in-place.

*yupikCorrector.sh*
Function: Spell-checker for Central Siberian Yupik files. Prompts user to modify each potential error found by the program.
How to use: ./yupikCorrector.sh [inputFile]
How it works: Reads line-by-line then tokenizes words, then checks if the words have errors in voicing (no voiced consonants next to unvoiced) or structure (C V C format).
Calls promptFix for each instance it finds, allowing user to call Find-and-Replace on entire file or Regex for specific instance. Also tells how many errors it found.
Notes: Find-and-Replace.sh needs to be in current directory for the program to function.

*corpusStats.sh*
Function: Prints out corpus stats for a given file. Gives character/grapheme frequency, line count, word count, character count, and average word length.
How to use: ./corpusStats.sh [inputFile] [EN/CSY*]
How it works: Uses built-in Bash command tools like cat and wc to tell stats about a file. Also counts every instance of each character/grapheme/word in the file and calculates frequency.
Notes: Defaults to English when used. Have to specify CSY, ESS, or Yupik at the end of each cmmand.

*fixFormatting.sh*
Function: Formats Central Siberian Yupik documents with font symbols.
How to use: ./fixFormatting.sh [inputFile] [outputFile*] [CSY/CAY/IPA/APA*]
How it works: User is given option 1 or option 2: The first formats the file into columns, then replaces font symbols. The latter skips the first step and just replaces the font symbols.
For Option 1, it puts the file on a single line, then newlines after every language tag (PE, NSY, etc). Then, it uses awk to break the lines into Yupik entries, notes, etc. based on punctuation.
For Option 2 (or after Option 1 is done formatting), it prompts the user which columns of the file to replace font symbols in, makes a temp file of each column, and uses sed to replace every
instance of font symbols with the designated cleanup array type (CSY/CAY/IPA/APA). It has a duplicate file of potential risky replacements from the sed that don't end in dashes, q's, or have
numbers as font symbols instead of letters. It then runs a second repair sed that replaces all the likely English back to its original self from the temp file.
Notes: If outputFile isn't entered, then inputFile will be modified in-place. If symbol cleanup type isn't entered, then it defaults to CSY (Central Siberian Yupik Latin orthography).

*transOrthography.sh*
Function: Enforces transparent orthography for Central Siberian Yupik files with IPA.
How to use: (Still WiP)
How it works: (Still WiP)
