#!/bin/bash

figlet -f slant "nmap XML" 

date=$(date -d "$D" '+%Y_%m')
nmap_params="-sC -O -sC --open"
nmap_bin="grc -c grc.conf nmap"
green='\033[0;32m'
nc='\033[0m'

folder=output

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

if [ -z $tenant ] || [ -z $ip_list ] || [ -z $proto ]; then
	echo "Sintax: sudo nmap_script -t tenant -p protocol [ tcp / udp or both ] -l ip_list_filename.txt"
	exit 1
fi

echo "Nmap parameters: ${nmap_params}"
echo "Protocol: ${proto}"
echo -n "Host List: "

while read host_ip; do
	echo -n "${host_ip}, "
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
else
         echo -e "\nError in protocol: tcp or udp or both, check sintax !!!"
         exit 1
fi

if [ $proto == "tcp" ] || [ $proto == "both" ]; then


         while read host_ip; do
                 protocol="tcp"
		 echo -e "\nRun scan for Tenant: ${green}$tenant${nc} | Protocol: ${green}TCP${nc} | Host: ${green}$host_ip${nc}"
                 ${nmap_bin} ${nmap_params} ${host_ip} -oX ${folder}/${tenant}_${date}_${protocol}_${host_ip}.xml
         done <$ip_list

else 

	echo -e "\nError in protocol: tcp or udp or both, check sintax !!!"
	exit 1
fi
