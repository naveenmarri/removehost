#!/bin/bash
#USAGE: removehost.sh epicavm1 0677
#Created by Naveen Marri
if [ $# -ne 2 ]
then
echo "USAGE: $0 hostname array"
exit 1
fi

hostname1=$1
storarray=$2

echo "Finding $hostname1 on $storarray"

mvname=`symaccess -sid $storarray list view -v |grep "Masking View Name" |grep -i $hostname1 |awk '{ print $NF }'`
echo "The Masking view for $hostname1 is: $mvname"

#Remove MV
echo "symaccess -sid $storarray delete view -name $mvname -unmap -nop"

sgname=`symaccess -sid $storarray list -type storage -v |grep "Storage Group Name" |grep -i $hostname1 |awk '{ print $NF }'`

#Remove SG
strdev=`symaccess -sid $storarray show $sgname -type storage |grep Devices |cut -d ' ' -f 23-`
echo "symaccess -sid $storarray -name $sgname -type storage remove devs $strdev"
echo "symaccess -sid $storarray -name $sgname -type storage delete -nop"

#Remove IG
igname=`symaccess -sid $storarray list -type initiator -v |grep "Initiator Group Name" |grep -i $hostname1 |awk '{ print $NF }'`
for i in `symaccess -sid $storarray show $igname -type initiator |grep WWN |awk '{ print $3 }'`; do echo "symaccess -sid 677 -name $igname -type initiator remove -wwn $i"; done
echo "symaccess -sid $storarray -name $igname -type initiator delete -nop"

#Remove Devs
strpool=`symdev -sid $storarray show $strdev |grep "Bound Thin Pool Name"| awk '{ print $6 }'`
echo "symconfigure -sid $storarray -cmd \"unbind tdev $strdev from pool $strpool;\" preview -nop"
echo "symconfigure -sid $storarray -cmd \"unbind tdev $strdev from pool $strpool;\" commit -nop"
echo "symconfigure -sid $storarray -cmd \"delete dev $strdev;\" preview -nop"
echo "symconfigure -sid $storarray -cmd \"delete dev $strdev;\" commit -nop"


echo
echo "Run the following on the appropriate switch"
echo "show zone active vsan 600 |grep $hostname1"
echo "show zone active vsan 601 |grep $hostname1"


exit 0
