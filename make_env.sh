#!/bin/bash -xe

cat <<EOF >${env}.yaml
rustedhalo_apt_repo_release: 'trusty-unstable'

public_address: "%{${public_address}}"
public_interface: "%{${public_interface}}"
private_address: "%{${private_address}}"
private_interface: "%{${private_interface}}"

baremetal::ilo_user: <ilo_username>
baremetal::ilo_password: <ilo_password>


rjil::ceph::osd::autogenerate: true
rjil::ceph::osd::autodisk_size: 10
rjil::ceph::osd::osd_journal_size: 2


rjil::system::accounts::active_users: [soren,bodepd,hkumar,jenkins,consul,pandeyop,jaspreet,amar]
rjil::system::accounts::sudo_users:
  admin:
    users: [soren,bodepd,hkumar,jenkins,consul,pandeyop,jaspreet,amar]

rjil::base::self_signed_cert: true

tempest::admin_password: tempest_admin
tempest::admin_username: tempest_admin

rjil::neutron::contrail::fip_pools:
  public:
    network_name: public_net
    subnet_name: public_subnet
    cidr: 100.1.0.0/24
    subnet_ip_start: 100.1.0.11
    subnet_ip_end: 100.1.0.254
    public: true
  private_shared:
    network_name: private_shared_net
    subnet_name: private_shared_subnet
    cidr: 99.0.0.0/24
    public: false
    tenants: ['tempest','testtenant']


ilo::network: ${ilo_network}
ilo::netmask: ${ilo_netmask}
ilo::gateway: ${ilo_gateway}
ilo::dhcp_range: '${ilo_dhcp_range}'

rjil::jiocloud::dhcp::interface: ${dhcp_interface}
rjil::jiocloud::dhcp::server_ipaddress: ${dhcp_server_ip}
rjil::jiocloud::dhcp::server_netmask: "%{hiera('ilo::netmask')}"

rjil::neutron::ovs::br_physical_interface: ${data_network_interface}
rjil::neutron::ovs::br_name: br-ctlplane
rjil::neutron::ovs::gateway: ${data_network_gateway}
# Setting up gcp1 as dns server for uc for now
rjil::neutron::ovs::nameservers: [<nameserver>]
rjil::neutron::network::undercloud::dns_nameservers: [<dnsserver>]
rjil::neutron::network::undercloud::gateway: ${data_network_gateway}
rjil::neutron::network::undercloud::pool_start: ${data_network_pool_start}
rjil::neutron::network::undercloud::pool_end: ${data_network_pool_end}
rjil::neutron::network::undercloud::cidr: ${data_network_cidr}

baremetal::active_nic_number: ${active_nic}

EOF
