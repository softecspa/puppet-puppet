# == class puppet::master
#
# Install and configures Puppet Master
#
# === Params
#
# [*ensure*]
#   Specify if the master should be present (default) or absent
#
# [*storeconfig*]
#   Backend type, only puppetdb is supported
#
# [*autosign*]
#   Set the autosign variable in puppet.conf
#   If true the master will sign each request
#
# [*puppetdb_server*]
#   Address of PuppetDB, default localhost
#
# [*puppetdb_port*]
#   Port of PuppetDB, default 8081
#
# [*reports*]
#   Report handler to use, default to puppetdb & DataDog
#
# [*version*]
#   Which version of puppet user for master, default is autogenerated
#
# [*master*]
#   URL of the master
#
# [*ca*]
#   URL of the CA
#
class puppet::master (
  $ensure          = 'present',
  $storeconfig     = false,
  $autosign        = false,
  $puppetdb_server = 'localhost',
  $puppetdb_port   = 8081,
  $reports         = 'puppetdb, datadog_reports',
  $version         = '',
  $master,
  $ca,) {
  validate_bool($autosign)

  if ($version != '') {
    class { 'puppet': version => $version, }
  } else {
    include puppet
  }

  if !($ensure in [
    'present',
    'absent',
    'latest']) {
    fail('ensure parameter must be one of present, absent or latest')
  }

  if !$storeconfig == false {
    if !($storeconfig in ['puppetdb']) {
      fail('storeconfig parameter must be false or puppetdb')
    }
  }

  # Packages
  package {
    'puppetmaster-common':
      ensure => $puppet::puppet_version;

    'puppetmaster-passenger':
      ensure => $puppet::puppet_version;

    'puppetmaster':
      ensure => $puppet::puppet_version;
  }

  include softec_apache

  class { 'apache::mod::passenger':
    passenger_root               => '/var/lib/gems/1.9.1/gems/passenger-4.0.53',
    passenger_default_ruby       => '/usr/bin/ruby1.9.1',
    mod_path                     => '/var/lib/gems/1.9.1/gems/passenger-4.0.53/buildout/apache2/mod_passenger.so',
    passenger_high_performance   => 'on',
    passenger_max_pool_size      => '15',
    passenger_pool_idle_time     => '200',
    passenger_max_requests       => '2500',
    passenger_stat_throttle_rate => '300'
  }

  $request_headers = [
    'unset X-Forwarded-For',
    'set X-SSL-Subject %{SSL_CLIENT_S_DN}e',
    'set X-Client-DN %{SSL_CLIENT_S_DN}e',
    'set X-Client-Verify %{SSL_CLIENT_VERIFY}e']
  $location = [{
      path            => '/balancer',
      provider        => 'location',
      allow           => 'from all',
      custom_fragment => 'SetHandler balancer-manager',
    }
    ]

  apache::vhost { $master:
    port              => '443',
    ssl               => true,
    docroot           => '/usr/share/puppet/rack/puppetmasterd/public/',
    ssl_cert          => "/var/lib/puppet/ssl/certs/${::fqdn}.pem",
    ssl_key           => "/var/lib/puppet/ssl/private_keys/${::fqdn}.pem",
    ssl_chain         => '/var/lib/puppet/ssl/certs/ca.pem',
    ssl_ca            => '/var/lib/puppet/ssl/certs/ca.pem',
    ssl_crl_path      => '/var/lib/puppet/ssl/ca',
    ssl_verify_client => 'optional',
    ssl_verify_depth  => '1',
    ssl_options       => '+StdEnvVars',
    request_headers   => $request_headers,
    rack_base_uris    => '/',
    error_log_file    => 'puppetmaster_err.log',
    access_log_file   => 'puppetmaster_acc.log',
    access_log_format => 'combined_forward',
    directories       => $location,
    setenv            => 'LANG it_IT.UTF-8',
  }

  file { 'puppetmaster-passenger-rack':
    path    => '/usr/share/puppet/rack/puppetmasterd/config.ru',
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0755',
    content => template('puppet/puppetmaster-rack.erb')
  }

  file { '/etc/default/puppetmaster':
    ensure  => present,
    require => Package['puppetmaster'],
  }

  # metti un template al file sopra e togli questa
  exec { 'puppetmaster-disable-startup':
    command => 'sed \'s/^START=yes/START=no/i\' -i~ /etc/default/puppetmaster',
    unless  => 'grep -q \'^START=no\' /etc/default/puppetmaster',
    require => File['/etc/default/puppetmaster'],
  }

  if ($ensure in [
    'present',
    'latest']) {
    package { 'puppetdb-terminus': ensure => $puppet::puppetdb::ensure; }
  }

  if $ensure != 'absent' {
    include apache::service
  }

  # aggiungere
  # /reports = store,datadog_reports
  augeas { 'puppet-master-config':
    context => '/files/etc/puppet/puppet.conf',
    changes => [
      "set master/autosign ${autosign}",
      "set master/certname ${master}",
      'set master/report true',
      'set master/pluginsync true',
      "set master/reports ${reports}",
      'set master/ssl_client_header SSL_CLIENT_S_DN',
      'set master/ssl_client_verify_header SSL_CLIENT_VERIFY',
      'set master/always_cache_features true',
      'set master/environmentpath $confdir/envs',

      ]
  }

  # Common modules shared between env
  $shared_modulepath = '/usr/share/puppet/modules'

  file { $shared_modulepath:
    ensure => directory,
    group  => 'admin',
    mode   => 02775,
  }

  file { '/etc/puppet/hieradata':
    ensure => directory,
    group  => 'admin',
    mode   => 02775,
  }

  file { '/etc/puppet/hiera.yaml':
    content => file('puppet/etc/hiera.yaml'),
    group  => 'admin',
    mode   => 02775,
  }

  file { '/etc/hiera.yaml':
    ensure => symlink,
    target => '/etc/puppet/hiera.yaml',
  }

  # http://docs.puppetlabs.com/puppetdb/1/connect_puppet_master.html
  case $storeconfig {
    'puppetdb' : {
      file { '/etc/puppet/routes.yaml':
        ensure  => present,
        content => "---\nmaster:\n  facts:\n    terminus: puppetdb\n    cache: yaml\n"
      }

      augeas { 'master-configuration-storeconfig':
        context => '/files/etc/puppet/puppet.conf',
        changes => [
          'set master/storeconfigs true',
          'set master/storeconfigs_backend puppetdb',
          ]
      }

      # puppetdb.conf is not in the augeas lens, so I specify it directly
      augeas { 'master-configuration-puppetdb':
        lens    => 'Puppet.lns',
        incl    => '/etc/puppet/puppetdb.conf',
        context => '/files/etc/puppet/puppetdb.conf',
        changes => [
          "set main/server ${puppetdb_server}",
          "set main/port ${puppetdb_port}",
          ]
      }
    }

    default    : {
      fail('PuppetDB is the only supported option for storeconfig')
    }
  }

  # pulizia del bucket
  tmpreaper::daily { '/var/lib/puppet/bucket/': time => '30d', }

}
