#!/bin/bash

date=$(date -d "$D" '+%Y_%m')
nmap_params="-Pn -sC -O --open"
red='\033[0;41m'
green='\033[0;32m'
nc='\033[0;0m'
folder=output
message_error="${red}\nSintax: sudo nmapexport -t tenant -p protocol [ tcp / udp or both ] -l ip_list_filename.txt${nc}"

if command -v grc &> /dev/null
then
	nmap_bin="grc -c grc.conf nmap"
else
	nmap_bin="nmap"
fi

if command -v figlet &> /dev/null
then
	cat banner.txt
else
        echo -e "${green}\nnmapExport.XML${nc}"
fi

trap_ctrlc()
{
    exit
}

duwp()
{
 	echo -e "\n"
 	read -p "Do you want to proceed? (yes/no) " yn

 	case $yn in
        	yes ) echo -e "\nok, we will proceed";;
        	no ) echo -e "\nexiting...";
                	exit;;
        	* ) echo -e "\ninvalid response";
                	exit 1;;
 	esac
}

nmap_run()
{
	if [ $1 == "udp" ]; then
		echo -e "\nRun scan for Tenant: ${green}$tenant${nc} | Protocol: ${green}udp${nc} | Host: ${green}$2${nc}"
		${nmap_bin} -sU ${nmap_params} ${2} -oX ${folder}/${tenant}_${date}_udp_${2}.xml -oN ${folder}/${tenant}_${date}_udp_${2}.txt -oG ${folder}/${tenant}_${date}_udp_${2}.gnmap
	elif [ $1 == "tcp" ]; then
		echo -e "\nRun scan for Tenant: ${green}$tenant${nc} | Protocol: ${green}tcp${nc} | Host: ${green}$2${nc}"
		${nmap_bin} ${nmap_params} ${2} -oX ${folder}/${tenant}_${date}_tcp_${2}.xml -oN ${folder}/${tenant}_${date}_tcp_${2}.txt -oG ${folder}/${tenant}_${date}_tcp_${2}.gnmap
	else	
		echo -e "\nRun scan for Tenant: ${green}$tenant${nc} | Protocol: ${green}udp${nc} | Host: ${green}$2${nc}"
		${nmap_bin} -sU ${nmap_params} ${2} -oX ${folder}/${tenant}_${date}_udp_${2}.xml -oN ${folder}/${tenant}_${date}_udp_${2}.txt -oG ${folder}/${tenant}_${date}_udp_${2}.gnmap
		echo -e "\nRun scan for Tenant: ${green}$tenant${nc} | Protocol: ${green}tcp${nc} | Host: ${green}$2${nc}"
		${nmap_bin} ${nmap_params} ${2} -oX ${folder}/${tenant}_${date}_tcp_${2}.xml -oN ${folder}/${tenant}_${date}_tcp_${2}.txt -oG ${folder}/${tenant}_${date}_tcp_${2}.gnmap
	fi
}

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

trap trap_ctrlc SIGHUP SIGINT SIGTERM

if [ ! -d $folder ]; then
    mkdir output
fi

if [ $(whoami) != 'root' ]; then
	echo -e "\nPlease run script as root or with sudo"
	exit 1
fi

while getopts t:p:l:L: flag
do
    case "${flag}" in
        t) tenant=${OPTARG};;
        p) proto=${OPTARG};;
        L) ip_list=${OPTARG};;
	l) ip_host=${OPTARG};;
    esac
done

if [ -z $tenant ]; then
	echo -e $message_error
	exit 1
fi

if [ -z $ip_list ] && [ -z $ip_host ]; then
	echo -e $message_error
	exit 1
fi

if [ $proto != "tcp" ] && [ $proto != "udp" ] && [ $proto != "both" ];then
	echo -e $message_error
	echo -e "Error in protocol: tcp or udp or both, check sintax !!!"
	exit 1
fi

echo -e "\nNmap parameters: ${green}${nmap_params}${nc}"
echo -e "Protocol: ${green}${proto}${nc}"
echo -n "Host List: "

if [ -z $ip_host ]; then
	while read host_ip; do
		echo -ne "${green}${host_ip}, ${nc}"
	done <$ip_list
else

	#validate ip format
	if valid_ip $ip_host; then
		echo -e "${green}${ip_host}${nc}" 
	else
		echo -ne "${ip_host}\n\n${red}Malformed IP Address !!!${nc}"
		exit 1
	fi
fi

#call to function do you want to proceed?
duwp

if [ -z $ip_host ];then

	while read host_ip; do

	     nmap_run $proto $host_ip

	done < $ip_list
else
	nmap_run $proto $ip_host
fi


sudo cat ${folder}/${tenant}_${date}*.txt | sudo tee ${folder}/${tenant}_${date}.nmap

echo -e "\n\nReview Output Scan ?"
duwp
nano -v -f nmap.nanorc ${folder}/${tenant}_${date}.nmap
