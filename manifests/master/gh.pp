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
    'softec_rsyslog',
    's3cmd',
    'skeleton',
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
    'php5',
    'pecl',
    'logrotate',
    'hostname',
    'devutils',
    'basepackages',
    'softec_apt',
    'softecscripts',
    'apache2',
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
    'softec_xen'
  ]

  puppet::master::module{ $softec_modules:
    updated => $autoupdate,
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
    'xinetd',
    'kvm',
    'apt',
    'concat',
    'mysql'
  ]

  puppet::master::module { $puppetlabs_modules:
    prefix  => 'puppetlabs',
  }

  ## Third-party forked modules
  $third_party_modules = [
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

  #Private_module on gitlab
  $gitlab_modules = [
    'sslcert',
    'ispconfig_cluster',
    'ispconfig_files',
    'ispconfig_master',
    'ispconfig_slave',
    'ispconfig_tomcat',
    'tomcat',
    'ispconfig_mirror',
    'varnish',
    'softec_registry'
  ]

  puppet::master::module { $gitlab_modules:
    author  => 'ops',
    server  => 'git.sftc.it',
    method  => 'ssh',
    identity  => '/etc/ssl/private/code_reader_key.key'
  }
}
