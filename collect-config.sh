case $1 in
        pre) STAGE="PRE"
                ;;
        post) STAGE="POST"
                ;;
        *)
                echo;echo -e "Usage ksh $0 pre|post"
                exit
                ;;
esac

function FN_OS_MAJOR_VERSION {
        if [[ $(command -v lsb_release) ]];then

                OS_MAJOR_VERSION=$(lsb_release -rs)
        else

                OS_MAJOR_VERSION=$( rpm -qa --queryformat '%{VERSION}\n' \
                                '(redhat|sl|slf|centos|oraclelinux)-release(|-server|-workstation|-client|-computenode)' \
                                | awk -F. '{print $1"."$2}' )

                typeset -a OS_VERSION_LIST
                OS_VERSION_LIST=(4 4.0 4.1 4.2 4.3 4.4 4.5 4.6 4.7 4.8 4.9 4AS. 4ES.\
                                 5 5.1 5.2 5.3 5.4 5.6 5.9 5.10 5.11 \
                                 6 6.0 6.1 6.2 6.3 6.4 6.5 6.6 6.7 6.8 6.9 6.10 \
                                 7 7.0 7.1 7.2 7.3 7.4 7.5 7.6 7.7 7.8 7.9 7.10 \
                                 8 8.0 8.1 8.2 8.3 8.4 8.5 8.6 8.7 8.8 8.9 8.10)

                ITEM_FOUND="N"

                for ITEM in "${OS_VERSION_LIST[@]}"; do
                    [[ $OS_MAJOR_VERSION == "$ITEM" ]] && { ITEM_FOUND="Y"; break;}
                done

                if [ $ITEM_FOUND != "Y" ];then
                        OS_MAJOR_VERSION=$(rpm -qa --queryformat '%{RELEASE}\n' \
                                '(redhat|sl|slf|centos|oraclelinux)-release(|-server|-workstation|-client|-computenode)' \
                                | awk -F. '{print $1"."$2}' )
                fi

                for ITEM in "${OS_VERSION_LIST[@]}"; do
                    [[ $OS_MAJOR_VERSION == "$ITEM" ]] && { ITEM_FOUND="Y"; break;}
                done

                [[ $ITEM_FOUND != "Y" ]] && { OS_MAJOR_VERSION="0.0"; }
        fi
}


SERVER_NAME=$(uname -n)
echo "Linux $STAGE-Migration Check and Collection"
CDATE="$(date +"%F-%H_%M_%S")"
DIR_NAME=${SERVER_NAME}_${STAGE}_mig_${CDATE}
OUTPUT_DIR="/cmf-bkp/${DIR_NAME}"
TEMP_FILE=$OUTPUT_DIR/TempFile
mkdir -p $OUTPUT_DIR/ERROR
mkdir -p $OUTPUT_DIR/BACKUP
OS_MAJOR_VERSION=""
echo "Collecting System Information for ${SERVER_NAME}"
echo "		UNAME"; uname -a > $OUTPUT_DIR/uname 2>$OUTPUT_DIR/ERROR/uname
echo "		OS release version"
	if [ -e /etc/SuSE-release ]
	then
	        cp -p /etc/SuSE-release $OUTPUT_DIR/os_release 2>$OUTPUT_DIR/ERROR/os_release
	elif [ -e /etc/redhat-release ]
	then
	        cp -p /etc/redhat-release $OUTPUT_DIR/os_release 2>$OUTPUT_DIR/ERROR/os_release
	fi
echo "		Network Name";uname -n > $OUTPUT_DIR/networkname 2>$OUTPUT_DIR/ERROR/networkname
echo "		UPTIME";uptime 2>$OUTPUT_DIR/ERROR/uptime |awk '{print $3" "$4}'|sed 's/.$//' > $OUTPUT_DIR/uptime
echo "		Main memory";free -g 2>$OUTPUT_DIR/ERROR/memsize |head -2 | awk '{print $1,$2}' |tail -1 > $OUTPUT_DIR/memsize
echo "		Swap memory";free -g 2>$OUTPUT_DIR/ERROR/swapsize |awk '{print $1,$2}' | tail -1 >> $OUTPUT_DIR/swapsize
echo "		No: of CPUs";grep 'processor' /proc/cpuinfo 2>$OUTPUT_DIR/ERROR/n_cpus | wc -l >$OUTPUT_DIR/n_cpus
echo "		Block devices";fdisk -l 2>$OUTPUT_DIR/ERROR/diskinformation |grep "Disk /dev/" 2>> $OUTPUT_DIR/ERROR/diskinformation\
		| awk -F, '{print $1}'  > $OUTPUT_DIR/diskinformation
echo "		Attached devices details"
	dmesg 2> $OUTPUT_DIR/ERROR/dmesg-attached-devices |grep -i "attached " \
	|grep -ve 's.[[:digit:]*]' |awk -F"Attached" '{print $1}' \
	|awk -F" " '{print $NF}'  > $OUTPUT_DIR/dmesg-attached-devices 2>> $OUTPUT_DIR/ERROR/dmesg-attached-devices
echo "		Disk Usage details";df -PTh 2> $OUTPUT_DIR/ERROR/diskusage |tail -n+2 \
			|grep -v 'tmpfs|systemd-1' |awk '{print $1" "$2" "$3" "$NF}' > $OUTPUT_DIR/diskusage
if [ -x /usr/symcli/bin/syminq ];
then
	echo "		Symmetrix/Clarion disks details"
	/usr/symcli/bin/syminq > $OUTPUT_DIR/sym-cla-disks 2>$OUTPUT_DIR/ERROR/sym-cla-disks
fi
echo "		Total No: Filesystems"
	df -hPT 2> $OUTPUT_DIR/ERROR/n_filesystems |grep -v 'Filesystem'|wc -l > $OUTPUT_DIR/n_filesystems
echo "		File system mounts"

	mount |grep -v 'devtmpfs\|systemd-1\|tmpfs' > $OUTPUT_DIR/mounts 2>$OUTPUT_DIR/ERROR/mounts
echo "		Device mappers"
	ls -l /dev/mapper | awk '{print $(NF-2)" "$(NF-1)" "$NF}' \
		| tail -n+3 > $OUTPUT_DIR/devicemapper 2> $OUTPUT_DIR/ERROR/devicemapper
echo "		SCSI Disk details";cat /proc/scsi/scsi > $OUTPUT_DIR/scsidetails 2>$OUTPUT_DIR/ERROR/scsidetails
echo "		Logical Volumes"
	pvdisplay > $OUTPUT_DIR/pvdisplay.out 2>$OUTPUT_DIR/ERROR/pvdisplay.out
	vgdisplay > $OUTPUT_DIR/vgdisplay.out 2>$OUTPUT_DIR/ERROR/vgdisplay.out
	lvdisplay > $OUTPUT_DIR/lvdisplay.out 2>$OUTPUT_DIR/ERROR/lvdisplay.out
	pvs -o +devices  > $OUTPUT_DIR/pvs2disks 2>$OUTPUT_DIR/ERROR/pvs2disks
	vgs  > $OUTPUT_DIR/vgs.out 2>$OUTPUT_DIR/ERROR/vgs.out
	lvs  > $OUTPUT_DIR/lvs.out 2>$OUTPUT_DIR/ERROR/lvs.out
	pvs 2> $OUTPUT_DIR/ERROR/n_pvs |grep -v 'PSize'|wc -l > $OUTPUT_DIR/n_pvs
	vgs 2> $OUTPUT_DIR/ERROR/n_vgs |grep -v 'VSize'|wc -l > $OUTPUT_DIR/n_vgs
	lvs 2> $OUTPUT_DIR/ERROR/n_lvs |grep -v 'LSize'|wc -l > $OUTPUT_DIR/n_lvs
echo "		File System details";cat /etc/fstab > $OUTPUT_DIR/fstab 2>$OUTPUT_DIR/ERROR/fstab
if [ -x /sbin/multipath ];then
	echo "		Multipath device details"
	/sbin/multipath -ll > $OUTPUT_DIR/multipathdevices 2>$OUTPUT_DIR/ERROR/multipathdevices
fi
if [ -x /etc/multipath.conf ];then
	echo "		Multipathing configuration"
	cp -p /etc/multipath.conf  $OUTPUT_DIR/multipath.conf 2>$OUTPUT_DIR/ERROR/multipath.conf
fi
echo "		Mounted NFS shares count";mount 2> $OUTPUT_DIR/ERROR/n_nfs \
		|grep -v 'rpc_pipefs' |grep -i nfs|wc -l > $OUTPUT_DIR/n_nfs
echo "		Mounted CIFS shares count";mount 2> $OUTPUT_DIR/ERROR/n_cifs \
		|grep -i 'cifs' |wc -l > $OUTPUT_DIR/n_cifs
##
## Firewall 
##
echo "		SELinux status"
	[[ $(command -v getenforce) ]] && { getenforce > $OUTPUT_DIR/selinuxinfo 2>$OUTPUT_DIR/ERROR/selinuxinfo; }
[[ -e /etc/selinux/config ]] && { cat /etc/selinux/config > $OUTPUT_DIR/selinuxconf 2>$OUTPUT_DIR/ERROR/selinuxconf; }
echo "		Copying Hosts file";cp -p /etc/hosts  $OUTPUT_DIR/hosts 2>$OUTPUT_DIR/ERROR/hosts
echo "		NIC kernel information"
	ip link show | grep 'mtu' 2>$OUTPUT_DIR/ERROR/interfacekernel > $OUTPUT_DIR/interfacekernel
echo "		IP Details";ip -4 addr show 2> $OUTPUT_DIR/ERROR/ipdetails |grep 'inet' \
		| awk -F" " '{print $NF" "$2}' > $OUTPUT_DIR/ipdetails
echo "		Copying NETWORK file";cp /etc/sysconfig/network $OUTPUT_DIR/network_file 2> $OUTPUT_DIR/ERROR/network_file
echo "		ROUTING details";ip route show > $OUTPUT_DIR/routing 2>$OUTPUT_DIR/ERROR/routing
echo "		Listening ports details"
		FN_OS_MAJOR_VERSION
		if [[ ${OS_MAJOR_VERSION} -ge 6 ]];then
			ss -4 -putlan 2> $OUTPUT_DIR/ERROR/listeningports \
				|awk '{split($NF,PRGNAME,"\""); print $1,$5,PRGNAME[2]}'\
				|uniq |grep -v "ssh$" > $OUTPUT_DIR/listeningports
		else
			ss -4 -ptlan 2> $OUTPUT_DIR/ERROR/listeningports \
			|awk '{split($NF,PRGNAME,"\""); print "TCP",$4,PRGNAME[2]}' \
			|uniq |grep -v "ssh$" > $OUTPUT_DIR/listeningports
			ss -4 -pulan 2>> $OUTPUT_DIR/ERROR/listeningports \
                        |awk '{split($NF,PRGNAME,"\""); print "UDP",$4,PRGNAME[2]}' \
			|uniq |grep -v "ssh$" >> $OUTPUT_DIR/listeningports
		fi
echo "		NIC Bonding details"
		if [ -d /proc/net/bonding ];then
			for BOND_FILE in "/proc/net/bonding/*"
			 do
				cat $BOND_FILE >> $OUTPUT_DIR/nicbonding 2>> $OUTPUT_DIR/ERROR/nicbonding
			done
                elif [ -e /sys/class/net/bonding_masters ] && [ ! -z /sys/class/net/bonding_masters ];then
			mkdir -p $OUTPUT_DIR/nicbonding 2> /dev/null
                        for BOND_FILE in "`cat /sys/class/net/bonding_masters`"
                         do
                            cat /sys/class/net/bonding_masters >> $OUTPUT_DIR/bonding_masters 2>> $OUTPUT_DIR/ERROR/bonding_masters
			    cp -rp /sys/class/net/$BOND_FILE $OUTPUT_DIR/nicbonding/ 2>> $OUTPUT_DIR/ERROR/nicbonding
                        done
		fi 
echo "		NTP status";ntpq -p 2>$OUTPUT_DIR/ERROR/ntpinfo | cut -c1-30 > $OUTPUT_DIR/ntpinfo
echo "		Time Zone details";date +%Z > $OUTPUT_DIR/timezone 2>$OUTPUT_DIR/ERROR/timezone
echo "		DNS Client configuration";cp -p /etc/resolv.conf $OUTPUT_DIR/resolv.conf 2>$OUTPUT_DIR/ERROR/resolv.conf
echo "		Running processes details"
		ps -ef --no-heading 2> $OUTPUT_DIR/ERROR/ruprocesses \
		|awk '{print $1,",",$8}' \
|grep -v '\-bash\|mingetty\|sshd:\|root , ps\|root , awk\|root , grep\|root , \[kworker|zabbix|resolve' > $OUTPUT_DIR/ruprocesses
echo "		SMON - System MONitor process status"
		ps -ef | grep -i smon | grep -v grep > $OUTPUT_DIR/smonstatus 2>$OUTPUT_DIR/smonstatus
echo "		PMON - Process MONitor process status"
		ps -ef | grep -i cmon | grep -v grep > $OUTPUT_DIR/pmonstatus 2>$OUTPUT_DIR/pmonstatus
echo "		Modules loaded"
		/sbin/lsmod 2>$OUTPUT_DIR/ERROR/modulesinfo |awk '{$NF ~ /^[a-z]+/;print $1,$4}' > $OUTPUT_DIR/modulesinfo
if [ -x /usr/local/bin/scli ];
then
	echo "		Collecting HBA information"
	/usr/local/bin/scli -g > $OUTPUT_DIR/hbainfo 2>$OUTPUT_DIR/ERROR/hbainfo
fi
if [ -x /sys/class/fc_host ];
then
	echo "		HBA FC Hosts information"
	if [ -x /usr/bin/systool ];
	then
		systool -c fc_host -v > $OUTPUT_DIR/fchostsinfo 2>$OUTPUT_DIR/ERROR/fchostsinfo
	else
		ls /sys/class/fc_host > $OUTPUT_DIR/fchostsinfo 2>$OUTPUT_DIR/ERROR/fchostsinfo
		cat /sys/class/fc_host/host[0-9]*/port_name > $OUTPUT_DIR/fchostsinfo 2>$OUTPUT_DIR/ERROR/fchostsinfo
	fi
fi
echo "		Installed RPM packages information"
rpm -qa --queryformat "%-{name}-%{version}-%{release}.%{arch}.rpm\n" > $OUTPUT_DIR/rpminformation 2>$OUTPUT_DIR/ERROR/rpminformation
if [ -x /sbin/powermt ];
then
	echo "		EMC Power devices details"
        /sbin/powermt display dev=all > $OUTPUT_DIR/emcpowerdevices 2>$OUTPUT_DIR/ERROR/emcpowerdevices
fi
echo "		Bootloader -GRUB- configuration";
if [ -e /boot/grub.conf ];
then
        cat /boot/grub.conf > $OUTPUT_DIR/grub.conf 2>$OUTPUT_DIR/ERROR/grub.conf
elif [ -e /boot/grub/menu.lst ];
then
	cat /boot/grub/menu.lst > $OUTPUT_DIR/grub.conf 2>$OUTPUT_DIR/ERROR/grub.conf
elif [ -e /boot/grub/grub.conf ];
then
	cat /boot/grub/grub.conf > $OUTPUT_DIR/grub.conf 2>$OUTPUT_DIR/ERROR/grub.conf
elif [ -e /boot/grub2/grub.cfg ];
then
	cat /boot/grub2/grub.cfg > $OUTPUT_DIR/grub.cfg 2>$OUTPUT_DIR/ERROR/grub.cfg
else
	echo "GRUB Configuration file does not exist" > $OUTPUT_DIR/ERROR/grub.conf
fi

echo "		dmidecode output backup";dmidecode > $OUTPUT_DIR/dmidecodeinfo 2>$OUTPUT_DIR/ERROR/dmidecodeinfo
echo "		dmesg backup";dmesg >  $OUTPUT_DIR/dmesglogs 2>$OUTPUT_DIR/dmesglogs

[[ $(command -v chkconfig) ]] && { echo "		Check config servies information"; \
				chkconfig --list > $OUTPUT_DIR/chkconfiginfo 2>$OUTPUT_DIR/ERROR/chkconfiginfo; }
echo "		Running services information";
echo "SERVICE_NAME,LOAD,STATUS,SUB_STATUS,DESCRIPTION" > $OUTPUT_DIR/servicestatus
if [[ $(command -v systemctl) ]];then
	systemctl list-units --no-legend --type service 2>> $OUTPUT_DIR/ERROR/servicestatus |head -n -7 \
                |awk '{if ($1=="●") {ROW_DATA=$2","$3","$4",""\"$5\"";$1=$2=$3=$4=$5="";}
                         			else {ROW_DATA=$1","$2","$3","$4"," ;$1=$2=$3=$4="";}\
			print ROW_DATA"\""$0"\"" }' >> $OUTPUT_DIR/servicestatus
elif [[ $(command -v service) ]];then
	service --status-all > $TEMP_FILE 2>> $OUTPUT_DIR/ERROR/servicestatus
	grep "is running..." $TEMP_FILE |awk -F" " '{print $1",Loaded,,Running," }' >> $OUTPUT_DIR/servicestatus
	grep "is stopped" $TEMP_FILE |awk -F" " '{print $1",,,Stopped," }' >> $OUTPUT_DIR/servicestatus
	grep "module not loaded" $TEMP_FILE |awk -F" " '{print $1",,,Not Loaded," }' >> $OUTPUT_DIR/servicestatus
	grep "is not running" $TEMP_FILE |awk -F" " '{print $1",,,Not Running," }' >> $OUTPUT_DIR/servicestatus
#	grep -v -e "is running" -e "is stopped" -e "module not loaded" -e "is not running" $TEMP_FILE \
#		|awk -F" " '{print $1",,,," }' >> $OUTPUT_DIR/servicestatus
else
	echo "Could not find Service details" >> $OUTPUT_DIR/ERROR/servicestatus
fi

ping -c1 $(uname -n) > $OUTPUT_DIR/dnslookup 2> $OUTPUT_DIR/ERROR/dnslookup

#if [ "$1" == "pre" ];
#then
#	echo "		boot folder backup";tar -pczf $OUTPUT_DIR/BACKUP/bootloader.tar.gz /boot/ 2>$OUTPUT_DIR/ERROR/bootloader_bkp
#	sed '/tar: Removing leading `\//d' $OUTPUT_DIR/ERROR/etcfolder_bkp > $OUTPUT_DIR/ERROR/etcfolder_bkp-tmp 2> /dev/null
#	echo "		etc folder backup";tar -pczf $OUTPUT_DIR/BACKUP/etcfolder.tar.gz /etc/ 2>$OUTPUT_DIR/ERROR/etcfolder_bkp
#	sed '/tar: Removing leading `\//d' $OUTPUT_DIR/ERROR/bootloader_bkp > $OUTPUT_DIR/ERROR/bootloader_bkp-tmp 2> /dev/null
#	echo "		log files backup"
#	tar -pczf $OUTPUT_DIR/BACKUP/logs.tar.gz /var/log/{*log,btmp,cron,dmesg,messages,secure,spooler,wtmp} \
#									2> $OUTPUT_DIR/ERROR/logs_bkp
#	sed '/tar: Removing leading `\//d' $OUTPUT_DIR/ERROR/logs_bkp > $OUTPUT_DIR/ERROR/logs_bkp-tmp 2> /dev/null
#
#	mv $OUTPUT_DIR/ERROR/etcfolder_bkp-tmp $OUTPUT_DIR/ERROR/etcfolder_bkp 2> /dev/null
#	mv $OUTPUT_DIR/ERROR/bootloader_bkp-tmp $OUTPUT_DIR/ERROR/bootloader_bkp 2> /dev/null
#	mv $OUTPUT_DIR/ERROR/logs_bkp-tmp $OUTPUT_DIR/ERROR/logs_bkp 2> /dev/null
#fi

echo "		Cleaning tempory data";

sed -e '/Current Hardware Clock: `\//d' -e '/^,,,,$/d' -e '/Not,,,,$/d' -e '/The,,,,$/d' $OUTPUT_DIR/servicestatus > $OUTPUT_DIR/servicestatus-tmp 2> /dev/null
mv $OUTPUT_DIR/servicestatus-tmp $OUTPUT_DIR/servicestatus 2> /dev/null

sed '/grep: \/proc/d' $OUTPUT_DIR/ERROR/servicestatus > $OUTPUT_DIR/ERROR/servicestatus-tmp
mv $OUTPUT_DIR/ERROR/servicestatus-tmp $OUTPUT_DIR/ERROR/servicestatus

sed '/capi not installed - No such file or directory/d' $OUTPUT_DIR/ERROR/servicestatus > $OUTPUT_DIR/ERROR/servicestatus-tmp
mv $OUTPUT_DIR/ERROR/servicestatus-tmp $OUTPUT_DIR/ERROR/servicestatus

sed '/ss: no socket tables to show with such filter/d' $OUTPUT_DIR/ERROR/listeningports > $OUTPUT_DIR/ERROR/listeningports-tmp
mv $OUTPUT_DIR/ERROR/listeningports-tmp $OUTPUT_DIR/ERROR/listeningports

for ERROR_FILE in $OUTPUT_DIR/ERROR/{lvdisplay.out,lvs.out,n_lvs,n_pvs,n_vgs,pvdisplay.out,vgdisplay.out,vgs.out}
do
        sed '/\/dev\/hdc: open failed: No medium found/d' $ERROR_FILE > "$ERROR_FILE-tmp"
        mv "$ERROR_FILE-tmp" $ERROR_FILE
done

rm -f $TEMP_FILE 2> /dev/null
#tar zcf /tmp/${FOLDERNAME}.tar.gz $OUTPUT_DIR 2> /dev/null
echo "Log files are stored in $OUTPUT_DIR"
echo "**** Completed ****"

