#!/bin/sh
#devicechk.sh

    # NOTES:
    # - This uses a webCoRE Piston to change the value of the virtual switch
    # - MACs in arp are retained even when iphones are sleeping. Using arp or ip neigh solves the appearing offline issue.
    #
    # I had to set up extra complexity because I already had "Away" virtual switches 
    # and didn't want to change the names and all the automations associated with them. 
    # Without that, the values can be handled much more simply. Also, I like arrays. 
    # As merlin sh does not support true arrays, this was my compromise. I may create 
    # a .csv file to pull the data from later.

scpdir=/jffs/scripts/
usrdir=${scpdir}users/
#   URL to curl to:
urlStr="https://graph-na04-useast2.api.smartthings.com/api/token/8f9f-96ca-436d-a511-7fc2/smartapps/installations/88b57806-43fc-4d67-a3e8-f9a5d/execute/:46c20:?device="
#   Device names in SmartThings:
Names="Phillip%20Away Yvie%20Away Charles%20Away PBPC YRPC PBLaptopE PBLaptopW YRLaptopE YRLaptopW"
#    Wired connection 0 for no 1 for yes:
Wired="000111010"
#   True Values:
TrueVal="off off off on on on on on on"          ##Remove if you don't need different values
#   Set False Values as default:
Values="on on on off off off off off off"
#   List of MAC address for each device:
MACAddrLst="58:D5:0A:FC:B9:1A 48:EB:62:42:EF:58 B2:BE:76:43:48:FE AA:AA:AA:AA:AA:AA D8:CB:8A:5E:1F:82 04:D4:C4:E1:FC:0F 5C:87:9C:04:43:6D AA:AA:AA:AA:AA:AA BE:BE:76:F3:58:77"
#   Create list of MAC addresses:
macaddress="`ip neigh|grep "..:.."|cut -d' ' -f5,6|tr '[a-f]' '[A-F]'`"
#macaddress="`arp|grep "..:.."|cut -d' ' -f4|tr '[a-f]' '[A-F]'`"
#   Get the number of MACs to check
#echo $(c() { echo $#; }; c $MACAddrLst)
#echo "$MACAddrLst" | awk '{print NF}'
CL=$(c() { echo $#; }; c $MACAddrLst)
i=1
Count=1
while [ $i -lt $CL ]; do #Set up variable to 
    i=$(($i+1))
    Count=$Count,$i
done

#Arguemnt handler:
if [ "$1" == "-r" -o "$1" == "-remove" ]; then
    rm -f $usrdir*
    if [ "`ls $usrdir|grep -c -e "."`" -eq "0" ]; then
        echo Devices Cleared
        exit 0
    else
        echo Devices Not Cleared:
        ls $usrdir
        exit 1
    fi
elif [ "$1" == "-c" -o "$1" == "-all" ]; then
    for Name in ${Names}; do
        CurName="`echo $Name|cut -d'%' -f1`"
        touch /jffs/scripts/users/$CurName
    done
    ls $usrdir
    exit
elif [ "$1" == "-l" -o "$1" == "-list" ]; then
    ls $usrdir
    exit
elif [ "$1" != "" ]; then
    echo -e "\n$0 [-h] [-c] [-a]\nNotifies and creates a list of online devices\n\n  -c Creates all devices\n  -r Removes all devices\n  -l Current list of devices\n  -h This help page\n"
    exit
fi

#Check if device is online
i=1
l=${#Count}
for MACCur in ${MACAddrLst}; do
    if [ "$i" = 1 ]; then
        sp1=""
        sp3="`echo $Values|cut -d' ' -f${Count:$(($i*2)):$(($l-$i*2))}`"
    elif [ "$i" = "$CL" ]; then
        sp1="`echo $Values|cut -d' ' -f${Count:0:$(($i*2-2))}`"
        sp3=""
    else
        sp1="`echo $Values|cut -d' ' -f${Count:0:$(($i*2-2))}`"
        sp3="`echo $Values|cut -d' ' -f${Count:$(($i*2)):$(($l-$i*2))}`"
    fi
	if [ "${Wired:$(($i-1)):1}" = "1" ]; then
	    MACCur=${MACCur}" R"
	fi
    sp2="`echo $Values|cut -d' ' -f${i}`"        ##Change to sp2=off if you remove TrueVal
    case "$macaddress" in
        *"${MACCur}"*)
        sp2="`echo $TrueVal|cut -d' ' -f${i}`"   ##Change to sp2=on if you remove TrueVal
        ;;
    esac
    Values="${sp1} ${sp2} ${sp3}"
    i=$(($i+1))
done

#Check device status and report if different
i=1
for Name in ${Names}; do
    var="`echo $Values|cut -d' ' -f$i`"
    CurName="`echo $Name|cut -d'%' -f1`"
    if [ "$var" = "`echo $TrueVal|cut -d' ' -f$i`" ]; then
        if [ ! -f $usrdir$CurName ]; then
            touch $usrdir$CurName
            curl "${urlStr}${Name}&request=${var}" -k
            echo  $CurName
        fi
    else
        if [ -f $usrdir$CurName ]; then
            rm -f $usrdir$CurName
            curl "${urlStr}${Name}&request=${var}" -k
            echo  $CurName
        fi
    fi
    i=$(($i+1))
done
