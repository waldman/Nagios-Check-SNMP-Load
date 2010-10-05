#!/bin/bash

###
# Written by Leon Waldman (le.waldman at gmail.com)
# This script is freely available on Github: http://github.com/waldman/Nagios-Check-SNMP-Load
# v0.2
###

# Exit codes:
# 0 OK
# 1 WARNING
# 2 CRITICAL
# 3 UNKNOWN


# How to use this Script?
usage(){
    echo "Usage:"
    echo " $0 -H <host> -w WLOAD1,WLOAD5,WLOAD15 -c CLOAD1,CLOAD5,CLOAD15 [-C snmp_community]"
    echo " $0 -h help"
}


# ERROR control 
ERROR=0


# Getting Options
while getopts C:H:w:c:h option; do
    case $option in
    H)
 HOST=$OPTARG
    ;;
    C)
 COMUNITY=$OPTARG
    ;;
    w)
 WARNING=$OPTARG
    ;;
    c)
 CRITICAL=$OPTARG
    ;;
    h)
 usage
 ERROR=1
    ;;
    *)
 usage
 ERROR=1
    ;;
    esac
done


# Checking Parameters
TESTW="`echo $WARNING| grep -o ','| wc -l`"
TESTC="`echo $CRITICAL| grep -o ','| wc -l`"
if [ $TESTW -ne 2 ]; then
    ERROR=1
fi
if [ $TESTC -ne 2 ]; then
    ERROR=1
fi
if [ -z "$HOST" ]; then
    ERROR=1
fi
if [ -z "$COMUNITY" ]; then
    exit 3
fi


### Party Start!
# Getting the load from server through SNMP
LOAD=`snmpwalk -v 1 -c $COMUNITY $HOST UCD-SNMP-MIB::laLoad 2>&1|awk '{ print $4 }'`
CHECK=`echo $LOAD|grep -o "\."|wc -l`
if [[ "${LOAD}" =~ "from" ]]
then
    echo "UNKNOWN - Timeout: No Response from $HOST"
    exit 3
elif [ $CHECK -ne 3 ]; then
    echo "UNKNOWN - snmpwalk output malformed."
    exit 3
fi


# print statements commented out but ready to enable for debugging
echo $WARNING | awk 'BEGIN{
 while ( "snmpwalk -v 1 -c '$COMUNITY' '$HOST' UCD-SNMP-MIB::laLoad" |getline )
 serverload[++i] = $NF
# print serverload[1]
# print serverload[2]
# print serverload[3]
}
{
 w=split(warning,warnval,",")
 c=split(critical,critval,",")
# print warnval[1]
# print warnval[2]
# print warnval[3]
# print critval[1]
# print critval[2]
# print critval[3]
if( serverload[1] > critval[1] ) { 
 print "Load : " serverload[1] " " serverload[2] " " serverload[3] " : " serverload[1] " > " critval[1] " : CRITICAL"; exit 2 
}
else if( serverload[2] > critval[2] ) { 
 print "Load : " serverload[1] " " serverload[2] " " serverload[3] " : " serverload[2] " > " critval[2] " : CRITICAL"; exit 2 
}
else if( serverload[3] > critval[3] ) { 
 print "Load : " serverload[1] " " serverload[2] " " serverload[3] " : " serverload[3] " > " critval[3] " : CRITICAL"; exit 2 
}
else if( serverload[1] > warnval[1] ) { 
 print "Load : " serverload[1] " " serverload[2] " " serverload[3] " : " serverload[3] " > " warnval[3] " : WARNING"; exit 1 
}
else if( serverload[2] > warnval[2] ) { 
 print "Load : " serverload[1] " " serverload[2] " " serverload[3] " : " serverload[3] " > " warnval[3] " : WARNING"; exit 1 
}
else if( serverload[3] > warnval[3] ) { 
 print "Load : " serverload[1] " " serverload[2] " " serverload[3] " : " serverload[3] " > " warnval[3] " : WARNING"; exit 1 
}
else {
 print "Load : " serverload[1] " " serverload[2] " " serverload[3] " : OK"; exit 0
}
}
END { exit }' warning=$WARNING critical=$CRITICAL
exit $?
### Party Over!
