#!/bin/bash -xe

echo "Please Enter Team Name"
read team_name
env_name="Dev-Test-"${team_name}
export env=${env_name}
echo "Do you have consul discovery token?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) echo Please Enter the token;read token;export consul_discovery_token=$token;break;;
        No ) export consul_discovery_token=$(curl -s http://consuldiscovery.linux2go.dk/new);echo export consul_discovery_token=${consul_discovery_token};break;;
    esac
done
echo "Please Enter Data Network Interface Ex-em4"
read data_network_interface
export data_network_interface=$data_network_interface

echo "Please Enter Data Network CIDR Ex-10.140.213.0/24"
read data_network_cidr
export data_network_cidr=$data_network_cidr
echo "Please Enter Data Network gateway Ex-10.140.213.1"
read data_network_gateway
export data_network_gateway=$data_network_gateway
echo "Please Enter Data Network Pool Start IP Ex-10.140.213.10"
read data_network_pool_start
export data_network_pool_start=$data_network_pool_start
echo "Please Enter Data Network Pool End IP Ex-10.140.213.90"
read data_network_pool_end
export data_network_pool_end=$data_network_pool_end


ipadd_fact=`echo $data_network_cidr | awk -F"." '{ print $1"_"$2"_"$3"_"$4}' | awk -F"/" '{ print $1"_"$2}'`
export facter_ipaddress_$ipadd_fact_24=$ipadd
export facter_interface_$ipadd_fact_24=$interface
export public_address="ipaddress_"$ipadd_fact
export private_address="ipaddress_"$ipadd_fact
export public_interface="interface_"$ipadd_fact
export private_interface="interface_"$ipadd_fact

echo "Please Enter the proxy server in the format of http://ipaddress:port"
read proxy
export env_http_proxy=$proxy
export env_https_proxy=$proxy
echo "Please Enter ip for dhcp interface Ex-10.204.213.10"
read dhcp_ip
export dhcp_server_ip=$dhcp_ip
echo "Please Enter ILO Network Ex-10.204.213.0"
read ilo_ip
export ilo_network=$ilo_ip
echo "Please Enter ILO Netmask Ex-255.255.255.0"
read ilo_netmask
export ilo_netmask=$ilo_netmask
echo "Please Enter ILO Gateway Ex-10.204.213.1"
read ilo_gateway
export ilo_gateway=$ilo_gateway
echo "Please Enter ILO DHCP Range Ex- 10.204.213.20 10.204.213.100"
read ilo_dhcp_range
export ilo_dhcp_range=$ilo_dhcp_range
echo "Please Enter ILO DHCP Interace EX-em1"
read dhcp_interface
export dhcp_interface=$dhcp_interface
echo "Please Enter active nic number Ex-4"
read active_nic
export active_nic=$active_nic
. ./common.sh

# If these aren't yet set (from credentials file, typically),
. ./make_userdata.sh

#Create env.yaml
. ./make_env.sh
#Copy env.yaml to temp
cp -av ./${env_name}.yaml /tmp
#Run Userdata.sh
. userdata.sh
