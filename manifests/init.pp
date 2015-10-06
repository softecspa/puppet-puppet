class puppet (
  $version          = '',
  $day_before_renew = '30') {
  # COMMON VARIABLES
  $puppet_run = '/usr/local/sbin/puppet-run'
  $puppet_cert_renew = '/usr/local/sbin/puppet-cert-renew'
  $registry = $::registry_url
  $solo = '/usr/local/bin/solo -port=58140'

  # con -i 5 ci riprova fino a 64 minuti dopo la chiamata, con 60 secondi
  # di -i ci riprova fino a 4h e mezzo dopo
  $puppet_run_cmd_dev = "${solo} ${puppet_run} -a 2 -q -m 2> /dev/null"
  $puppet_run_cmd_prod = "${solo} ${puppet_run} -a 2 -q -m 2> /dev/null"
  $augeas_lenses_dir = '/usr/share/augeas/lenses/dist'

  # Module defaults
  File {
    group => 'admin',
    mode  => '0664',
  }

  Package {
    require => [
      Class['apt'],
  }

  case $::lsbdistcodename {
    'hardy' : {
      $puppet_env_version = $environment ? {
        'production' => '2.7.18-1puppetlabs1',
        default      => '2.7.20~hardy~ppa1',
      }
      $facter_version = '1.6.18~lucid~ppa1'
    }

    'lucid': {
      $puppet_env_version = 'latest'
      $facter_version = 'latest'
    }

    default : {
      $puppet_env_version = '3.7.5-1puppetlabs1'
      $facter_version = '2.4.3-1puppetlabs1'
    }
  }

  case $::lsbdistcodename {
    'lucid' : {
        softec_apt::mirror::repo { 'puppetlabs':
            title  => 'puppetlabs',
            enable => true,
            url    => 'http://apt.puppetlabs.com',
            repos  => 'main',
        }

        softec_apt::mirror::repo { 'puppetlabs-deps':
            title  => 'puppetlabs-deps',
            enable => true,
            url    => 'http://apt.puppetlabs.com',
            repos  => 'dependencies',
        }
    }
    default : {
      apt::source { 'puppetlabs':
        location => 'http://apt.puppetlabs.com',
        repos    => 'main',
        key      => '47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30',
      }

      apt::source { 'puppetlabs-deps':
        location => 'http://apt.puppetlabs.com',
        repos    => 'dependencies',
        key      => '47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30',
      }
    }
  }

  # for latest augeas packages. Not for trusty
  if $::lsbdistcodename != 'trusty' {
    softec_apt::ppa { 'skettler/puppet':
      key    => 'F02E13A8C7F16065114C757F19803648C18789EA',
      mirror => true
    }
  }

  $puppet_version = $version ? {
    ''      => $puppet_env_version,
    default => $version
  }

  if $::lsbdistcodename == 'precise' {
    softec_apt::ppa { 'raphink/augeas-1.0.0':
      key => 'CF6D4DF76A7B62DDCE6C3D99EEDBF1C2AE498453',
    }

    softec_apt::ppa { 'brightbox/ruby-ng':
      key => '80F70E11F0F0D5F10CB20E62F5DA5F09C3173AA6'
    }->
    package {
      'ruby1.9.1':
        ensure => present;

      'ruby1.9.1-dev':
        ensure => present;

      'ruby-switch':
        ensure => present;
    } ->
    exec { 'switch ruby1.9.1':
      command => 'ruby-switch --set ruby1.9.1',
      unless  => 'ruby-switch --check | grep Currently | awk \'{print $3}\' | grep \'ruby1.9.1\''
    }

  }

  $libaugeas_ruby_v = $::lsbdistcodename ? {
    'lucid' => 'libaugeas-ruby1.8',
    default => 'libaugeas-ruby1.9.1'
  }
  $rubygems_package_name = $::lsbdistcodename ? {
    'trusty' => 'rubygems1.9.1',
    default  => 'rubygems',
  }

  # INSTALL
  package {
    'augeas-lenses':
      ensure => latest;

    'augeas-tools':
      ensure => latest;

    'libaugeas-ruby':
      ensure => latest;

    $libaugeas_ruby_v:
      ensure => latest;

    $rubygems_package_name:
      ensure => latest;

    'libaugeas0':
      ensure => latest;
  }

  apt::pin {
    'puppet':
      packages => [
        'puppet',
        'puppet-common'],
      version  => $puppet_version,
      priority => '1001';

    'facter':
      packages => 'facter',
      version  => $facter_version,
      priority => '1001'
  } ->
  package {
    'puppet':
      ensure => $puppet_version;

    'puppet-common':
      ensure => $puppet_version;

    'facter':
      ensure => $facter_version;
  }

  # CONFIG
  # TODO: chiarire a cosa serve questo qui
  # suppongo serva per il modulo SSH, ma da qui non si capisce
  # esplicitiamo la dipendenza con una define puppet::augeaslens{ 'ssh': } da 
  # mettere nel modulo openssh. E magari con l'occasione tiriamo fuori augeas 
  # dal modulo puppet
  file { "${augeas_lenses_dir}/ssh.aug":
    ensure  => present,
    require => Package['augeas-lenses'],
    source  => 'puppet:///modules/puppet/ssh.aug',
    owner   => 'root'
  }

  file { '/etc/default/puppet':
    ensure  => present,
    require => Package['puppet'],
  }

  # #569: disable running as a service
  exec { 'puppet-disable-startup':
    command => '/bin/sed \'s/^START=yes/START=no/i\' -i~ /etc/default/puppet',
    unless  => '/bin/grep -q \'^START=no\' /etc/default/puppet',
    require => File['/etc/default/puppet'],
  }

  # Script that runs puppet until it exists without errors
  file { $puppet_run:
    ensure  => present,
    owner   => 'root',
    mode    => '0775',
    source  => 'puppet:///modules/puppet/sbin/puppet-run',
    require => Package['util-linux'],
  }

  file { $puppet_cert_renew:
    ensure  => present,
    owner   => 'root',
    mode    => '0775',
    content => template('puppet/sbin/puppet-cert-renew.erb')
  }

  # Pre&Post etckeeper script, pushed only if not present in official package
  file {
    '/etc/puppet/etckeeper-commit-pre':
      source  => 'puppet:///modules/puppet/etc/etckeeper-commit-pre',
      mode    => '0775',
      require => Package['puppet'];

    '/etc/puppet/etckeeper-commit-post':
      source  => 'puppet:///modules/puppet/etc/etckeeper-commit-post',
      mode    => '0775',
      require => Package['puppet'];
  }

  # da aggiungere??
  # "set agent/certname $fqdn",
  # "set agent/server $server",
  # "set agent/environment ${puppet_env}",
  augeas { 'puppet-agent-config':
    context => '/files/etc/puppet/puppet.conf',
    changes => [
      'set main/prerun_command /etc/puppet/etckeeper-commit-pre',
      'set main/postrun_command /etc/puppet/etckeeper-commit-post',
      'set main/pluginsync true', # non serve più da puppet 3.x
      'set agent/masterport 443',
      'set agent/graph true',
      'set agent/graphdir /var/puppet',
      'set agent/report true'],
    require => [
      File['/etc/puppet/etckeeper-commit-pre'],
      File['/etc/puppet/etckeeper-commit-post'],
      Package['puppet'],
      ],
  }

  # Remove warning on template_dir setting in old puppet packages
  ini_setting { 'puppet-templatedir-warning-remove':
    ensure  => absent,
    path    => '/etc/puppet/puppet.conf',
    section => 'main',
    setting => 'templatedir',
  }



  case $environment {
    'production' : {
      # in produzione, una volta tra le 11 e le 13 e una volta
      # tra le 14 e le 16, dal lunedi al giovedi compresi
      # Fx - sposto l'intervallo del mattino a 9-13
      # Fx - 13/02/2013 - tolgo l'esecuzione del puppet al pomeriggio

      $hour1 = fqdn_rand(2, 'puppet run') + 09
      $hour2 = fqdn_rand(2, 'puppet run') + 11
      $hour3 = fqdn_rand(2, 'puppet run') + 13
      $minute = fqdn_rand(59, 'puppet run')

      cron { 'puppet-cron-onetime':
        command => $puppet_run_cmd_prod,
        user    => 'root',
        weekday => [
          1,
          2,
          3,
          4],
        minute  => [$minute],
        hour    => [
          $hour1,
          $hour2,
          $hour3],
        require => [
          File[$puppet_run],
          File['/usr/local/bin/solo']],
      }
    }

    default      : {
      # tutto ciò che non è produzione è sviluppo
      # una esecuzione ogni ora, tutti i giorni in 8-14
      $minute = fqdn_rand(59, 'puppet run')

      cron { 'puppet-cron-onetime':
        command => $puppet_run_cmd_dev,
        user    => 'root',
        weekday => '*',
        minute  => [$minute],
        hour    => '8-14',
        require => [
          File[$puppet_run],
          File['/usr/local/bin/solo']],
      }
    }
  }

  $minute_renew = fqdn_rand(59, 'puppet cert renew')

  # rinnovo dei certificati
  cron { 'puppet-cert-renew':
    command => '/usr/local/sbin/puppet-cert-renew > /dev/null',
    user    => 'root',
    weekday => '*',
    minute  => $minute_renew,
    hour    => '03',
    require => File['/usr/local/sbin/puppet-cert-renew']
  }

}
