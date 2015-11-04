#!/bin/bash
 
PASSLENGTH=10
LETTERS=(a b c d e f g h i j k l m n o q p r s t u v w x y z 1 2 3 4 5 6 7 8 9 0 Q W E R T Z U I O P A S D F G H J K L Y X C V B N M)
 
#########################################################################
#                                                                       #
#                                                                       #
#                       Password generator Script                       #
#                                                                       #
#               Description: generates random passwords with            #
#               LETTERS and a length of PASSLENGTH                      #
#                                                                       #
#               (c) copyright 2008                                      #
#                 by Maniac                                             #
#                                                                       #
#                                                                       #
#########################################################################
#                       License                                         #
#  This program is free software. It comes without any warranty, to     #
#  the extent permitted by applicable law. You can redistribute it      #
#  and/or modify it under the terms of the Do What The Fuck You Want    #
#  To Public License, Version 2, as published by Sam Hocevar. See       #
#  http://sam.zoy.org/wtfpl/COPYING for more details.                   #
#########################################################################
 
 
 
# ------------------ NOTHING TO CHANGE BELOW THIS LINE -----------------
 
LENGTH=${#LETTERS[@]}
 
NEWPASS=""
 
newletter()
{
    RANDOM=$(head -1 /dev/urandom | od -N 1 | awk '{ print $2 }')
 
    let "NUMBER = $RANDOM % $LENGTH"
 
   if [ ! -z $NUMBER ] ; then
     NEWPASS=$NEWPASS${LETTERS[$NUMBER]}
   fi
}
 
rerun()
{
    while [ "${#NEWPASS}" -lt "$PASSLENGTH" ] ; do
        newletter
    done
}
 
newletter
rerun
 
echo $NEWPASS
