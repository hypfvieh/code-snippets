# code-snippets
Code-Snippets I developed, previously hosted on my own webpage.

The structure is one folder per used programming language.

## Bash

### systemstatistics.sh
If you are a linux server administrator it could be nice to see some system related information on shell login (local or ssh).

This script is does it for you. It shows the current system load, running logins, Zombie Processes and uptime.

### spinningwheel.sh
Everybody knows them, but most of the time they are used by perl or python scripts.
I talk about the spinning wheels in a shell.

This is a simple bash implementation of a spinning wheel. You can convert this code to a function which you export to a extra script and call it. If your process is done, you can stop the spinner by sending SIGTERM, SIGINT or SIGKILL to it.


### passwordgenerator.sh
If you need passwords, random passwords are usually your first choice!
Often online generators or seperate programs were used.

Now here is a small random-password generator written in bash. It may not be the nicest or cleanest, but hell it works Wink

Call: just run the script

Changeable Values:
LETTERS -> All letters/numbers/special characters you want to include in your generated passwords
PASSLENGTH -> minimum Length of the password

### natophonetics.sh
If you have to work with random Passwords and different fonts, it's sometimes hard to see if a a sign is a capital letter or lower case letter, or a number.

To spell passwords easier it's nice to use the NATO phonetics-alphabet. This script translates a string to the corresponding NATO phonetic-spelling.

Call: script.sh STRINGTOTRANSLATE

## Perl

### duplicatefinder.pl
This script finds duplicated entries in checksum DBs created with my "Checksum Database Creator".
To use it simply call:

perl dupfind.pl -d database.db -o duplicates.txt
(I guess your checksum DB is called database.db).

This script has been tested on Linux and on Windows using Cygwin+Cygwin-Perl.
If you have any problems on Cygwin please double-check that you use the current Cygwin-Version and that you really call the cygwin-perl interpreter (check with perl --version, there should be something like "cygwin-thread-multi" in the output. If you see something like "provided by ActiveState" then you are running the wrong Perl!)


###checksumDbGenerator.pl
This script creates a checksum database.
The checksum is MD5, the file format looks like this:
checksum|filename

Please note: This script will ignore modified files. It only computes NEW files (either really new or renamed).

To run this script you have to create a list of files which will get md5-sumed.
You can do this using the GNU find commandline tool available on linux or in cygwin on Windows:
find /my/path/ -type f > file.lst

Now you can call the script like this:
perl genchksumdb.pl -d database.db -i file.lst

This script has been tested on Linux and on Windows using Cygwin+Cygwin-Perl.
If you have any problems on Cygwin please double-check that you use the current Cygwin-Version and that you really call the cygwin-perl interpreter (check with perl --version, there should be something like "cygwin-thread-multi" in the output. If you see something like "provided by ActiveState" then you are running the wrong Perl!)


## PHP

### SimpleLog.class.php

This is a simple class for logging certain information to a flat file.
You can customize the output as you like. See the descriptive text in file header.

## Pascal/Free Pascal/Delphi/Lazarus

### xmodem
This is a simple Xmodem implementation used for sending files to a remote host using RS-232 (Serial Port).

Only sending is implemented at the moment.
To use this code you need the Synapse Synaser Serialport-Library (http://www.ararat.cz/synapse/doku.php/download)
