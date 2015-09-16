# == class puppet::master::gh
#
#  Downloads specific projects from Softec's GH account
#
# === Params
#
# === Examples
#
class puppet::master::gh (
  $autoupdate,
){

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
    'softec_rsyslog',
    's3cmd',
    'memcache',
    'sysctl',
    'softec_sysctl',
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
    'php',
    'softec_php',
    'pecl',
    'logrotate',
    'hostname',
    'devutils',
    'basepackages',
    'softec_apt',
    'softecscripts',
    'common',
    'cron',
    'git',
    'memcached',
    'iptables',
    'ispconfig_iptables',
    'fluentd',
    'ispconfig_logarchive',
    'ia32_libs',
    'backuppc',
    'softec_backuppc',
    'adduserconf',
    'softec_adduserconf',
    'apparmor',
    'automysqlbackup',
    'awstools',
    'ispconfig_courier',
    'dexgate',
    'dhclient',
    'dhttpd',
    'dnsmasq',
    'etckeeper_maintenance',
    'fail2ban',
    'ispconfig_fail2ban',
    'java',
    'softec_kvm',
    'monit',
    'nsupdate',
    'ntp',
    'postfix',
    'softec_postfix',
    'ispconfig_postfix',
    'subversion',
    'nfs',
    'softec_nfs',
    'proftpd',
    'ispconfig_proftpd',
    'sudo',
    'softec_sudo',
    'nginx',
    'sslterminus',
    'locales',
    'ssh',
    'softec_ssh',
    'apc',
    'ispconfig_apc',
    'perl',
    'softec_mysql',
    'boto',
    'rclocal',
    'ispconfig_httpd_logs',
    'ispconfig_memcached',
    'ispconfig_packages',
    'ispconfig_postfix_graph',
    'postfix_graph',
    'ispconfig_zendopcache',
    'softec_mylvmbackup',
    'ispconfig_named',
    'nrpe',
    'softec_xen',
    'nagios',
    'softec_newrelic',
    'hpsdr',
    'modprobe',
  ]

  # moduli da noi creati o forkati softec
  puppet::master::module{ $softec_modules:
    author  => 'softecspa',
    prefix  => 'puppet',
    updated => $autoupdate,
  }

  # moduli di puppetlabs da noi modificati
  # abbiamo aggiunto della roba runtime
  puppet::master::module{ 'mysql':
    author  => 'softecspa',
    prefix  => 'puppetlabs',
    updated => $autoupdate,
  }


  # moduli di PuppetLabs presi as-is
  $puppetlabs_modules = [
    'dhcp',
    'lvm',
    'mongodb',
    'nodejs',
    'ruby',
    'stdlib',
    'tftp',
    'vcsrepo',
    'xinetd',
    'kvm',
    'apt',
    'concat',
    'apache',
    'inifile'
  ]

  puppet::master::module { $puppetlabs_modules:
    prefix => 'puppetlabs',
    author => 'puppetlabs',
  }

  ## Third-party modules
  # TODO: eliminare questi moduli da gh/softecspa
  $third_party_modules = [
    'thomasvandoren/etckeeper',
    'smintz/mysql_mmm',
    'fsalum/newrelic',
    'fsalum/redis',
    'tobru/smokeping',
    'maestrodev/wget',
  ]

  puppet::master::module { 'docker':
    prefix => 'garethr',
    author => 'garethr',
  }

  puppet::master::module{ $third_party_modules:
    prefix => 'puppet',
  }

  puppet::master::module{ 'datadog':
    author => 'DataDog',
    repo_url => 'https://github.com/DataDog/puppet-datadog-agent.git',
  }

  ## Concat: new style module
  # TODO: droppare pupmod-concat da gh/softecspa
  puppet::master::module { 'onyxpoint/concat':
    target   => 'concat_new',
    repo_url => 'https://github.com/onyxpoint/pupmod-concat.git',
  }

  ## Puppi
  # TODO: droppare puppi da gh/softecspa
  puppet::master::module { 'example42/puppi':
    prefix => '',
  }

  puppet::master::module { 'backups':
    author => 'softecspa',
    prefix => 'evenup',
  }
}
