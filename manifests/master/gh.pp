# == class puppet::master::gh
#
#  Downloads specific projects from Softec's GH account
#
# === Params
#
# === Examples
#
class puppet::master::gh {
  # all repos reside on softec account
  Puppet::Master::Module {
    author  => 'softecspa',
  }

  ## Softec modules
  $softec_modules = [
    'haproxy',
    'heartbeat',
    'jenkins',
    'mcollective',
    'motd',
    'mutt',
    'pdftools',
    'php5_mssql',
    'powerdns',
    'quota',
    'rabbitmq',
    'repmand',
    'resolvconf',
    'rkhunter',
    'rsyslog',
    's3cmd',
    'skeleton',
    'sysctl',
    'softec',
    'supervisor',
    'swftools',
    'thttpd',
    'tmpreaper',
    'vim',
    'webalizer',
    'zookeeper',
    'jetty',
    'solr',
    'ispconfig_solr',
    'ispconfig_nginx',
    'ispconfig_zookeeper',
    'puppet',
    'php5',
    'mysql',
    'pecl',
    'logrotate',
    'hostname',
    'devutils',
  ]

  puppet::master::module{ $softec_modules:
    updated => true,
  }

  ## PuppetLabs modules
  $puppetlabs_modules = [
    'dhcp',
    'lvm',
    'mongodb',
    'nodejs',
    'ruby',
    'stdlib',
    'tftp',
    'vcsrepo',
    'xinetd'
  ]

  puppet::master::module { $puppetlabs_modules:
    prefix  => 'puppetlabs',
  }

  ## Third-party forked modules
  $third_party_modules = [
    'concat', # vecchio modulo, prenderlo da forge
    'datadog',
    'etckeeper',
    'mysql_mmm',
    'newrelic',
    'redis',
    'smokeping',
    'modprobe',
  ]

  puppet::master::module{ $third_party_modules: }

  ## Concat: new style module
  puppet::master::module { 'pupmod-concat':
    target => 'concat_new',
    prefix => ''
  }

  ## Puppi
  puppet::master::module { 'puppi':
    prefix => '',
  }

}
