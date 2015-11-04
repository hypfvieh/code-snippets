#!/bin/bash
 
#########################################################################
#                                                                       #
#                                                                       #
#                      Login system state                               #
#                                                                       #
#               Description: Prints some system information             #
#                            on shell login                             #
#                                                                       #
#               (c) copyright 2010-2011                                 #
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
 
LANG=C
 
timefix()
{
        case $1 in
 
                0)      echo 00 ;;
                1)      echo 01 ;;
                2)      echo 02 ;;
                3)      echo 03 ;;
                4)      echo 04 ;;
                5)      echo 05 ;;
                6)      echo 06 ;;
                7)      echo 07 ;;
                8)      echo 08 ;;
                9)      echo 09 ;;
                *)      echo $1 ;;
        esac
 
}
 
 
# Get Zombieprocesses
ZOMBIE=$(ps -A -o state | grep Z | wc -l)
 
if [ "$ZOMBIE" -ge 1 ] ; then
        ZPROCESSESID=$(ps -A -o state,pid | grep Z | awk '{print $2}')
        ZPROCESSCOMM=$(ps -A -o state,comm | grep Z | awk '{print $2}')
fi
 
# Get Processes
PROCCOUNT=$(ps -A | wc -l)
PROCCOUNT=$[PROCCOUNT-1]
 
 
# Get Load
LOADNOW=$(cat /proc/loadavg | cut -d " " -f 1)
LOAD5=$(cat /proc/loadavg | cut -d " " -f 2)
LOAD15=$(cat /proc/loadavg | cut -d " " -f 3)
 
LOGINS=$(who -u | wc -l)
 
 
# Get Uptime
REST=0
 
TOTALUP=$(cat /proc/uptime | cut -d " " -f 1 | cut -d "." -f 1)
DAYS=$[$TOTALUP/86400]
 
RDAYS=$[$DAYS*86400]
REST=$[$TOTALUP-$RDAYS]
 
if [ "$DAYS" -le 0 ] ; then
        DAYS="00"
fi
 
 
if [ "$REST" -gt 0 ] ; then
        HOURS=$[$REST/3600]
 
        RHOURS=$[$HOURS*3600]
        REST=$[$REST-$RHOURS]
 
        MYHOURS=$(timefix $HOURS)
 
        if [ "$REST" -gt 0 ] ; then
                MINUTES=$[$REST/60]
                RMINUTES=$[$MINUTES*60]
                REST=$[$REST-$RMINUTES]
 
                MYMINUTES=$(timefix $MINUTES)
 
                MYSECONDS=$(timefix $REST)
        fi
else
        MYHOURS="00"
        MYMINUTES="00"
        MYSECONDS="00"
fi
 
 
echo -en "\t\t\t System State\n"
echo "---------------------------------------------------------------"
echo "Welcome to $(hostname -f)"
echo
 
echo "Load (now): "$LOADNOW
echo "Load (5m) : "$LOAD5
echo "Load (15m): "$LOAD15
echo
echo "Kernel: $(uname -r)"
 
if [ "$DAYS" -eq 0 ] ; then
        echo "Uptime: $MYHOURS:$MYMINUTES:$MYSECONDS"
elif [ "$DAYS" -eq 1 ] ; then
        echo "Uptime: $DAYS day $MYHOURS:$MYMINUTES:$MYSECONDS"
else
        echo "Uptime: $DAYS days $MYHOURS:$MYMINUTES:$MYSECONDS"
fi
echo
echo "Active Logins: "$LOGINS
echo "Zombie-Processes: "$ZOMBIE
        if [ "$ZOMBIE" -ge 1 ] ; then
        echo -en "\t Zombie-ProcessIDs: $ZPROCESSESID\n"
        echo -en "\t Zombie-ProcessCMD: $ZPROCESSCOMM\n"
        fi
echo "Running Processes: "$PROCCOUNT
echo "---------------------------------------------------------------"
 
echo
