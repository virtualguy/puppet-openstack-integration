# Deploy OpenStack resources needed to run Tempest

class openstack_integration::provision {

  include ::openstack_integration::config

  $os_auth_options = "--os-username admin --os-password a_big_secret --os-tenant-name openstack --os-auth-url ${::openstack_integration::config::keystone_auth_uri}/v2.0"

  exec { 'manage_m1.nano_nova_flavor':
    path     => '/usr/bin:/bin:/usr/sbin:/sbin',
    provider => shell,
    command  => "nova ${os_auth_options} flavor-create m1.nano 42 128 0 1",
    unless   => "nova ${os_auth_options} flavor-list | grep m1.nano",
  }
  Keystone_user_role['admin@openstack'] -> Exec['manage_m1.nano_nova_flavor']

  exec { 'manage_m1.micro_nova_flavor':
    path     => '/usr/bin:/bin:/usr/sbin:/sbin',
    provider => shell,
    command  => "nova ${os_auth_options} flavor-create m1.micro 84 128 0 1",
    unless   => "nova ${os_auth_options} flavor-list | grep m1.micro",
  }
  Keystone_user_role['admin@openstack'] -> Exec['manage_m1.micro_nova_flavor']

  neutron_network { 'public':
    tenant_name               => 'openstack',
    router_external           => true,
    provider_physical_network => 'external',
    provider_network_type     => 'flat',
  }
  Keystone_user_role['admin@openstack'] -> Neutron_network<||>

  neutron_subnet { 'public-subnet':
    cidr             => '172.24.5.0/24',
    ip_version       => '4',
    allocation_pools => ['start=172.24.5.10,end=172.24.5.200'],
    gateway_ip       => '172.24.5.1',
    enable_dhcp      => false,
    network_name     => 'public',
    tenant_name      => 'openstack',
  }

  glance_image { 'cirros':
    ensure           => present,
    container_format => 'bare',
    disk_format      => 'qcow2',
    is_public        => 'yes',
    # TODO(emilien) optimization by 1/ using Hiera to configure Glance image source
    # and 2/ if running in the gate, use /home/jenkins/cache/files/ cirros image.
    # source        => '/home/jenkins/cache/files/cirros-0.3.4-x86_64-disk.img',
    source           => 'http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img',
  }
  glance_image { 'cirros_alt':
    ensure           => present,
    container_format => 'bare',
    disk_format      => 'qcow2',
    is_public        => 'yes',
    # TODO(emilien) optimization by 1/ using Hiera to configure Glance image source
    # and 2/ if running in the gate, use /home/jenkins/cache/files/ cirros image.
    # source        => '/home/jenkins/cache/files/cirros-0.3.4-x86_64-disk.img',
    source           => 'http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img',
  }
  Keystone_user_role['admin@openstack'] -> Glance_image<||>
}
