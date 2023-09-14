#!/bin/bash

date=$(date -d "$D" '+%Y_%m')
nmap_params="-sC -O -sC --open"
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
	figlet -f slant "nmapExport.XML" -w 100
else
        echo -e "${green}\nnmapExport.XML${nc}"
fi

trap_ctrlc()
{
    exit
}

trap trap_ctrlc SIGHUP SIGINT SIGTERM

if [ ! -d $folder ]; then
    mkdir output
fi

if [ $(whoami) != 'root' ]; then
	echo -e "\nPlease run script as root or with sudo"
	exit 1
fi

while getopts t:p:l: flag
do
    case "${flag}" in
        t) tenant=${OPTARG};;
        p) proto=${OPTARG};;
        l) ip_list=${OPTARG};;
    esac
done

if [ -z $tenant ] || [ -z $ip_list ]; then
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

while read host_ip; do
	echo -ne "${green}${host_ip}, ${nc}"
done <$ip_list

echo -e "\n"
read -p "Do you want to proceed? (yes/no) " yn

case $yn in 
	yes ) echo -e "\nok, we will proceed";;
	no ) echo -e "\nexiting...";
		exit;;
	* ) echo -e "\ninvalid response";
		exit 1;;
esac

if [ $proto == "udp" ] || [ $proto == "both" ]; then

         while read host_ip; do
                 protocol="udp"
                 echo -e "\nRun scan for Tenant: ${green}$tenant${nc} | Protocol: ${green}UDP${nc} | Host: ${green}$host_ip${nc}"
                 ${nmap_bin} -sU ${nmap_params} ${host_ip} -oX ${folder}/${tenant}_${date}_${protocol}_${host_ip}.xml
         done <$ip_list
fi

if [ $proto == "tcp" ] || [ $proto == "both" ]; then


         while read host_ip; do
                 protocol="tcp"
		 echo -e "\nRun scan for Tenant: ${green}$tenant${nc} | Protocol: ${green}TCP${nc} | Host: ${green}$host_ip${nc}"
                 ${nmap_bin} ${nmap_params} ${host_ip} -oX ${folder}/${tenant}_${date}_${protocol}_${host_ip}.xml
         done <$ip_list
fi
