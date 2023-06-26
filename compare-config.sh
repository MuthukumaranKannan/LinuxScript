SERVER_NAME="$(uname -n)"
BASE_DIR="/cmf-bkp"

if [ $# -eq 0 ]; then
        PRE_CHECK_LOG=$(ls -td "$BASE_DIR/$SERVER_NAME"_PRE*/ | head -1)
        POST_CHECK_LOG=$(ls -td "$BASE_DIR/$SERVER_NAME"_POST*/ | head -1)
elif [ $# -ne 2 ]; then
        echo
        echo "Usage : ksh $0 [<pre> <post>]"
        exit
else
        PRE_CHECK_LOG=$1
        POST_CHECK_LOG=$2
fi
CDATE="$(date +"%F-%H_%M_%S")"
DIR_NAME=${SERVER_NAME}_compare
OUTPUT_DIR="$BASE_DIR/${DIR_NAME}"

mkdir -p $OUTPUT_DIR
if [ -d "$PRE_CHECK_LOG" ];then
        if [ -d "$POST_CHECK_LOG" ];then
                LOGFILE=${SERVER_NAME}_pre_post_compare_${CDATE}
                echo "====================================================================" |tee ${OUTPUT_DIR}/${LOGFILE}
                echo "Comparing Pre-Migration Vs Post Migration configuration.." |tee -a ${OUTPUT_DIR}/${LOGFILE}
                echo "====================================================================" |tee -a ${OUTPUT_DIR}/${LOGFILE}
                echo "======= SERVER NAME : ${SERVER_NAME}" |tee -a ${OUTPUT_DIR}/${LOGFILE}
                echo "====================================================================" |tee -a ${OUTPUT_DIR}/${LOGFILE}
                echo "======= DATE-TIME : $CDATE" |tee -a ${OUTPUT_DIR}/${LOGFILE}
                echo "Pre Migration configuration files folder given is : $PRE_CHECK_LOG" |tee -a ${OUTPUT_DIR}/${LOGFILE}
                echo "Post Migration configuration files folder given is : $POST_CHECK_LOG" |tee -a ${OUTPUT_DIR}/${LOGFILE}
                echo "====================================================================" |tee -a ${OUTPUT_DIR}/${LOGFILE}
        else
                echo "Post Migration directory does not exist : $POST_CHECK_LOG";exit
        fi
else
        echo "Pre Migration directory does not exist : $PRE_CHECK_LOG";exit
fi
ERROR_CNT=0

_displayprogress()
{

LISTED_ITEM="yes"
case $1 in
	uname)		DISPLAY_MSG="UNAME Information"
			;;
	os_release)	DISPLAY_MSG="OS version and release"
			;;
	networkname)	DISPLAY_MSG="Network Name"
			;;
        uptime)		DISPLAY_MSG="Server uptime"
			;;
        memsize)	DISPLAY_MSG="Main Memory size"
			;;
	swapsize)	DISPLAY_MSG="SWAP Memory size"
			;;
        n_cpus)		DISPLAY_MSG="Number of CPUs"
			;;
        diskinformation)
			DISPLAY_MSG="Disk details"
			;;
        dmesg-attached-devices)
			DISPLAY_MSG="Attached devices list from dmesg"
                        ;;
        diskusage)	DISPLAY_MSG="Disk usage details"
			;;
	sym-cla-disks)	DISPLAY_MSG="Symmetriz/Clarion Disks"
			;;
        n_filesystems)	DISPLAY_MSG="Number of available file systems"
			;;
	mounts)		DISPLAY_MSG="Mounted file systems"
			;;
        devicemapper)	DISPLAY_MSG="Device mappers"
			;;
        scsidetails)	DISPLAY_MSG="SCSI devices"
			;;
        pvdisplay.out)	DISPLAY_MSG="Physical volumes attributes"
			;;
        vgdisplay.out)	DISPLAY_MSG="Volume group attributes"
			;;
        lvdisplay.out)	DISPLAY_MSG="Logical volumes attributes"
			;;
        pvs2disks)	DISPLAY_MSG="Physical volumes --> Disks mapping"
			;;
        vgs.out)	DISPLAY_MSG="Volume groups information"
			;;
        lvs.out)	DISPLAY_MSG="Logical volumes information"
			;;
        n_pvs)		DISPLAY_MSG="Number of Physical volumes"
			;;
        n_vgs)		DISPLAY_MSG="Number of Volume groups"
			;;
        n_lvs)		DISPLAY_MSG="Number of Logical volumes"
			;;
        fstab)		DISPLAY_MSG="File System TABLE - fstab"
			;;
	multipathdevices)
			DISPLAY_MSG="Multpath Devices"
			;;
	multipath.conf)	DISPLAY_MSG="Multpath - Configuration file"
			;;
        n_nfs)		DISPLAY_MSG="Number of mounted Network File System shares - NFS"
			;;
        n_cifs)		DISPLAY_MSG="Number of mounted Common Internet File System shares - CIFS"
			;;
	selinuxconf)	DISPLAY_MSG="SELINUX Config file"
			;;
	selinuxinfo)	DISPLAY_MSG="SELINUX Status in Kernel"
			;;
	hosts)		DISPLAY_MSG="/etc/hosts - Configuration file"
			;;
        interfacekernel)
			DISPLAY_MSG="Network Interface details in current loaded kernel"
			;;
        ipdetails)	DISPLAY_MSG="Internet Protocol (IP) Address"
			;;
	network)	DISPLAY_MSG="/etc/sysconfig/network - Configuration file"
			;;
        routing)	DISPLAY_MSG="Routing configuration"
			;;
        listeningports)	DISPLAY_MSG="Listening ports"
			;;
	nicbonding)	DISPLAY_MSG="NIC Bonding"
			;;
	bonding_masters)
			DISPLAY_MSG="NIC Bonding"
			;;
        ntpinfo)	DISPLAY_MSG="Network Time Protocol - NTP"
			;;
        timezone)	DISPLAY_MSG="Time Zone"
			;;
	resolv.conf)	DISPLAY_MSG="/etc/resolve.conf"
			;;
        ruprocesses)	DISPLAY_MSG="Running User processes"
			;;
        smonstatus)	DISPLAY_MSG="SMON - System MONitor process"
			;;
        pmonstatus)	DISPLAY_MSG="PMON - Process MONitor process"
			;;
        modulesinfo)	DISPLAY_MSG="Modules Loaded"
			;;
	hbainfo)	DISPLAY_MSG="HBA Info"
			;;
	fchostsinfo)	DISPLAY_MSG="Fiber Channel Hosts"
			;;
        rpminformation)	DISPLAY_MSG="Installed RPM Packages information"
			;;
	emcpowerdevices)	DISPLAY_MSG="EMC Power Adapter devices"
			;;
        grub.conf)	DISPLAY_MSG="Boot loader - GRUB configuration"
			;;
        dmidecodeinfo)	DISPLAY_MSG="DMI Decode information"
			;;
        chkconfiginfo)	DISPLAY_MSG="Runlevel Services enablement"
			;;
        servicestatus)	DISPLAY_MSG="All running services status"
			;;
	dnslookup)	DISPLAY_MSG="DNS Lookup status - On Target"
                        ;;
        *)
                LISTED_ITEM="no"
                        ;;
esac

[[ ${LISTED_ITEM} == "yes" ]] && { echo -e "Comparing $DISPLAY_MSG";echo -e "Comparing $DISPLAY_MSG"  >> ${OUTPUT_DIR}/${LOGFILE}; }

}

for CFGFILE in $PRE_CHECK_LOG/*
do
        STATUS=""
        CFGFILE=$(basename "$CFGFILE")
if [ "$CFGFILE" != "ERROR" ] && [ "$CFGFILE" != "BACKUP" ] && [ "$CFGFILE" != "uptime" ] && [ "$CFGFILE" != "dnslookup" ] && [ "$CFGFILE" != "dmidecodeinfo" ] && [ "$CFGFILE" != "dmesglogs" ];then
                _displayprogress "${CFGFILE}"
                if [ -f "$POST_CHECK_LOG/$CFGFILE" ];then
                        IFS=$'\n' STATUS=($(awk 'NR==FNR{a[$0];next}(!($0 in a)){print "LINE#",NR,":",$0}' $POST_CHECK_LOG/$CFGFILE $PRE_CHECK_LOG/$CFGFILE))
#			if [ "$STATUS" != "" ];then
			if [ "${#STATUS[@]}" -ne 0 ];then
                        	echo -e "**** ERROR **** Found some mismatch in file $POST_CHECK_LOG/$CFGFILE" \
						|tee -a ${OUTPUT_DIR}/${LOGFILE}
#				echo $STATUS |tee -a ${OUTPUT_DIR}/${LOGFILE};echo
				for E_LINE in ${STATUS[@]} 
					do
						echo $E_LINE |tee -a ${OUTPUT_DIR}/${LOGFILE}
				done
				echo
				ERROR_CNT=$((ERROR_CNT+1))
			else
				echo "                                  ..... OK" |tee -a ${OUTPUT_DIR}/${LOGFILE}
			fi
		else
			echo -e "\nThe file - $CFGFILE - does not existing in $POST_CHECK_LOG"
			read -p "Do you wish to [C]ontinue or [E]xit ? " STATUS
			case $STATUS in
				C | c)  continue;
					;;
				*)      break;
					;;
			esac
                fi
fi

done
echo "Checking DNS Lookup" |tee -a ${OUTPUT_DIR}/${LOGFILE}
ping -c1 $(uname -n) >/dev/null 2>/dev/null
PING_RESULT=$?
if [[ $PING_RESULT -eq 0 ]] || [[ $PING_RESULT -eq 1 ]];
then
        echo "                                  ..... OK" |tee -a ${OUTPUT_DIR}/${LOGFILE}
else
	echo -en "\033[0;31m";echo -en "\033[43m";
	ERROR_CNT=$((ERROR_CNT+1))
	echo -en "DNS Lookup is not working." |tee -a ${OUTPUT_DIR}/${LOGFILE}
	echo -en "\033[0m";echo |tee -a ${OUTPUT_DIR}/${LOGFILE}
fi

echo -e "\n\n=============================================================" |tee -a ${OUTPUT_DIR}/${LOGFILE}
echo -e "\n Total number of issues found : $ERROR_CNT" |tee -a ${OUTPUT_DIR}/${LOGFILE}
echo -e " DATE : $(date +"%F-%T")" |tee -a ${OUTPUT_DIR}/${LOGFILE}
echo -e " Log stored in : ${OUTPUT_DIR}/${LOGFILE}" |tee -a ${OUTPUT_DIR}/${LOGFILE}
echo -e "\n====================  END  ==================================" |tee -a ${OUTPUT_DIR}/${LOGFILE}
