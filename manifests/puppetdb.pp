# == class puppet::puppetdb
#
# Install PuppetDB and configure it to use
#
# === Params
#
# [*ensure*]
#   Specify if the master should be present (default) or absent
#
# [*db_type*]
#   Backend type, supported values are hsqldb or postgresql
#
# [*db_host*]
#   (Postgres only) URL of the DBMS
#
# [*db_name*]
#   (Postgres only) Name ofthe DB of the DBMS
#
# [*db_user*]
#   (Postgres only) User used to connect to the DBMS
#
# [*db_pass*]
#   (Postgres only) Password used to connect to the DBMS
#
class puppet::puppetdb(
  $ensure      = 'present',
  $host        = 'localhost',
  $host_port   = '8080',
  $ssl_host    = 'localhost',
  $ssl_port    = '8081',
  $ssl_key     = '/etc/puppetdb/ssl/private.pem',
  $ssl_cert    = '/etc/puppetdb/ssl/public.pem',
  $ssl_ca_cert = '/etc/puppetdb/ssl/ca.pem',
  $db_type     = 'hsqldb',
  $db_host     = 'localhost',
  $db_name     = '',
  $db_user     = '',
  $db_pass     = '',
  )
{

  if ! ($db_type in [ 'hsqldb', 'postgresql' ]) {
    fail('db_type parameter must be one of hsqldb or postgresql')
  }

  $puppetdb_version = '1.6.2-1puppetlabs1'

  apt::pin {'puppetdb':
    packages  => 'puppetdb',
    version   => $puppetdb_version,
    priority  => '1001'
  }->
  package { 'puppetdb':
    ensure => $puppetdb_version,
  }

  service { 'puppetdb':
    enable  => true,
    ensure  => running,
  }

  file { "puppetdb-database-ini":
    path    => "/etc/puppetdb/conf.d/database.ini",
    owner   => 'puppetdb',
    group   => 'puppetdb',
    mode    => '0640',
    content => template('puppet/puppetdb/database.ini.erb'),
    notify  => Service["puppetdb"]
  }

  file { "puppetdb-jetty-ini":
    path    => "/etc/puppetdb/conf.d/jetty.ini",
    owner   => 'puppetdb',
    group   => 'puppetdb',
    mode    => '0640',
    content => template('puppet/puppetdb/jetty.ini.erb'),
    notify  => Service["puppetdb"]
  }

}
