#
# Copyright 2015 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case $::osfamily {
  'Debian': {
    $ipv6 = false
  }
  'RedHat': {
    $ipv6 = true
  }
  default: {
    fail("Unsupported osfamily (${::osfamily})")
  }
}

include ::openstack_integration
class { '::openstack_integration::config':
  ssl  => true,
  ipv6 => $ipv6,
}
include ::openstack_integration::cacert
include ::openstack_integration::rabbitmq
include ::openstack_integration::mysql
include ::openstack_integration::keystone
class { '::openstack_integration::glance':
  backend => 'rbd',
}
include ::openstack_integration::neutron
class { '::openstack_integration::nova':
  libvirt_rbd => true,
}
class { '::openstack_integration::cinder':
  backend => 'rbd',
}
include ::openstack_integration::ceilometer
include ::openstack_integration::aodh
include ::openstack_integration::gnocchi
include ::openstack_integration::ceph
include ::openstack_integration::provision

case $::osfamily {
  'Debian': {
    # UCA is being updated and Ceilometer is currently broken
    $telemetry_enabled = false
  }
  'RedHat': {
    $telemetry_enabled = true
  }
  default: {
    fail("Unsupported osfamily (${::osfamily})")
  }
}

class { '::openstack_integration::tempest':
  cinder     => true,
  ceilometer => $telemetry_enabled,
  aodh       => $telemetry_enabled,
}
