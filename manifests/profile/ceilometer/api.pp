# The profile to set up the Ceilometer API
# For co-located api and worker nodes this appear
# after stein::profile::ceilometer::agent
class stein::profile::ceilometer::api {
  stein::resources::controller { 'ceilometer': }

  stein::resources::firewall { 'Ceilometer API':
    port => '8777',
  }

  class { '::ceilometer::keystone::auth':
    password         => hiera('stein::ceilometer::password'),
    public_address   => hiera('stein::controller::address::api'),
    admin_address    => hiera('stein::controller::address::management'),
    internal_address => hiera('stein::controller::address::management'),
    region           => hiera('stein::region'),
  }

  class { '::ceilometer::agent::central':
  }

  class { '::ceilometer::expirer':
    time_to_live => '2592000'
  }

  # For the time being no upstart script are provided
  # in Ubuntu 12.04 Cloud Archive. Bug report filed
  # https://bugs.launchpad.net/cloud-archive/+bug/1281722
  # https://bugs.launchpad.net/ubuntu/+source/ceilometer/+bug/1250002/comments/5
  if $::osfamily != 'Debian' {
    class { '::ceilometer::alarm::notifier':
    }

    class { '::ceilometer::alarm::evaluator':
    }
  }

  class { '::ceilometer::collector': }

  include ::stein::common::ceilometer

  mongodb_database { 'ceilometer':
    ensure  => present,
    tries   => 20,
    require => Class['mongodb::server'],
  } 

  mongodb_user { 'ceilometer':
    ensure        => present,
    password_hash => mongodb_password('ceilometer', 'password'),
    database      => ceilometer,
    roles         => ['readWrite', 'dbAdmin'],
    tries         => 10,
    require       => [Class['mongodb::server'], Class['mongodb::client']],
  }

  Class['::mongodb::server'] -> Class['::mongodb::client'] -> Exec['ceilometer-dbsync']
}
