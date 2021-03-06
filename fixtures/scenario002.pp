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
    $ipv6           = false
    # ironic-conductor is broken for Ubuntu Trusty
    # https://bugs.launchpad.net/cloud-archive/+bug/1530869
    $ironic_enabled = false
  }
  'RedHat': {
    $ipv6           = true
    $ironic_enabled = true
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
  backend => 'swift',
}
include ::openstack_integration::neutron
include ::openstack_integration::nova
include ::openstack_integration::cinder
include ::openstack_integration::swift
include ::openstack_integration::ironic
include ::openstack_integration::mongodb
include ::openstack_integration::provision


class { '::openstack_integration::tempest':
  cinder => true,
  swift  => true,
  ironic => $ironic_enabled,
}
