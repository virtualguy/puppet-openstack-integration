# Configure the Cinder service
#
# [*backend*]
#   (optional) Cinder backend to use.
#   Can be 'iscsi' or 'rbd'.
#   Defaults to 'iscsi'.
#
class openstack_integration::cinder (
  $backend = 'nfs',
) {

  include ::openstack_integration::config

  rabbitmq_user { 'cinder':
    admin    => true,
    password => 'an_even_bigger_secret',
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq'],
  }
  rabbitmq_user_permissions { 'cinder@/':
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => Class['::rabbitmq'],
  }

  class { '::cinder::db::mysql':
    password => 'cinder',
  }
  class { '::cinder::keystone::auth':
    public_url      => "http://${::openstack_integration::config::ip_for_url}:8776/v1/%(tenant_id)s",
    internal_url    => "http://${::openstack_integration::config::ip_for_url}:8776/v1/%(tenant_id)s",
    admin_url       => "http://${::openstack_integration::config::ip_for_url}:8776/v1/%(tenant_id)s",
    public_url_v2   => "http://${::openstack_integration::config::ip_for_url}:8776/v2/%(tenant_id)s",
    internal_url_v2 => "http://${::openstack_integration::config::ip_for_url}:8776/v2/%(tenant_id)s",
    admin_url_v2    => "http://${::openstack_integration::config::ip_for_url}:8776/v2/%(tenant_id)s",
    password        => 'a_big_secret',
  }
  class { '::cinder':
    database_connection => 'mysql+pymysql://cinder:cinder@127.0.0.1/cinder?charset=utf8',
    rabbit_host         => $::openstack_integration::config::ip_for_url,
    rabbit_port         => $::openstack_integration::config::rabbit_port,
    rabbit_userid       => 'cinder',
    rabbit_password     => 'an_even_bigger_secret',
    rabbit_use_ssl      => $::openstack_integration::config::ssl,
    verbose             => true,
    debug               => true,
  }
  class { '::cinder::api':
    keystone_password   => 'a_big_secret',
    auth_uri            => $::openstack_integration::config::keystone_auth_uri,
    identity_uri        => $::openstack_integration::config::keystone_admin_uri,
    default_volume_type => 'BACKEND_1',
    service_workers     => 2,
    public_endpoint     => "http://${::openstack_integration::config::ip_for_url}:8776",
    bind_host           => $::openstack_integration::config::host,
  }
  class { '::cinder::quota': }
  class { '::cinder::scheduler': }
  class { '::cinder::scheduler::filter': }
  class { '::cinder::volume':
    volume_clear => 'none',
  }
  class { '::cinder::cron::db_purge': }
  class { '::cinder::glance':
    glance_api_servers  => "${::openstack_integration::config::base_url}:9292",
  }
  case $backend {
    'iscsi': {
      class { '::cinder::setup_test_volume':
        size => '15G',
      }
      cinder::backend::iscsi { 'BACKEND_1':
        iscsi_ip_address => '127.0.0.1',
      }
    }
    'rbd': {
      cinder::backend::rbd { 'BACKEND_1':
        rbd_user        => 'openstack',
        rbd_pool        => 'cinder',
        rbd_secret_uuid => '7200aea0-2ddd-4a32-aa2a-d49f66ab554c',
      }
      # make sure ceph pool exists before running Cinder API & Volume
      Exec['create-cinder'] -> Service['cinder-api']
      Exec['create-cinder'] -> Service['cinder-volume']
    }
    'nfs': {
      cinder::backend::nfs { 'BACKEND_1':
        nfs_shares => '127.0.0.1:/primary/cinder',
      }
    }
    default: {
      fail("Unsupported backend (${backend})")
    }
  }
  class { '::cinder::backends':
    enabled_backends => ['BACKEND_1'],
  }
  cinder_type { 'BACKEND_1':
    ensure     => present,
    properties => ['volume_backend_name=BACKEND_1'],
  }

}
