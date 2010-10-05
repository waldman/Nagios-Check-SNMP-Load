#!/bin/bash
###
# Writed by Leon Waldman (le.waldman at gmail.com)
# Any Improvement ( And please, if you can, improve it!:) ) please send a copy to me! ;)
###

# Exit codes:
# 0	Ok
# 1	Warning
# 2	Critical
# 3	Unknow

# How to use this Script?
usage(){
    echo "Usage:"
    echo " $0 -H <host> -w WLOAD1,WLOAD5,WLOAD15 -c CLOAD1,CLOAD5,CLOAD15 [-C snmp_community]"
    echo " $0 -h help"
} 

# ERRORr control 
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
TESTW="echo $WARNING| grep -o ","| wc -l"
TESTC="echo $CRITICAL| grep -o ","| wc -l"
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
    ERROR=1
fi

if [ $ERROR -ne 0 ]; then
    usage
    exit 3
fi

### Party Start!
# Getting the load from server thru SNMP
LOAD=`snmpwalk -v 1 -c $COMUNITY $HOST .1.3.6.1.4.1.2021.10.1.3|awk '{ print $4 }'`
CHECK=`echo $LOAD|grep -o "\."|wc -l`
if [ $CHECK -ne 3 ]; then
    echo "UNKNOW - snmpwalk output malformed."
    exit 3
fi

# Getting Values Load
L1=`echo $LOAD|awk '{ print $1 }'`
L2=`echo $LOAD|awk '{ print $2 }'`
L3=`echo $LOAD|awk '{ print $3 }'`

LC1=`echo $LOAD|awk '{ print $1 }'|sed 's/\.//g'`
LC2=`echo $LOAD|awk '{ print $2 }'|sed 's/\.//g'`
LC3=`echo $LOAD|awk '{ print $3 }'|sed 's/\.//g'`

# Getting Values Warning
W1=`echo $WARNING|awk -F , '{ print $1 }'|sed 's/\.//g'`
W2=`echo $WARNING|awk -F , '{ print $2 }'|sed 's/\.//g'`
W3=`echo $WARNING|awk -F , '{ print $3 }'|sed 's/\.//g'`

# Getting Critical Values
C1=`echo $CRITICAL|awk -F , '{ print $1 }'|sed 's/\.//g'`
C2=`echo $CRITICAL|awk -F , '{ print $2 }'|sed 's/\.//g'`
C3=`echo $CRITICAL|awk -F , '{ print $3 }'|sed 's/\.//g'`

# Faz a Magica!!
if [[ $LC1 -gt $C1  ]] || [[ $LC2 -gt $C2  ]] || [[ $LC3 -gt $C3  ]]; then
    echo "LOAD CRITICAL - load average: $L1 $L2 $L3"
    exit 2
elif [[ $LC1 -gt $W1  ]] || [[ $LC2 -gt $W2  ]] || [[ $LC3 -gt $W3  ]]; then
    echo "LOAD WARNING - load average: $L1 $L2 $L3"
    exit 1
else
    echo "LOAD OK - load average: $L1 $L2 $L3"
    exit 0
fi

### Party Over!
