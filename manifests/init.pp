class puppet (
  $version = '',
  $day_before_renew = '30'
) {
  # COMMON VARIABLES
  $puppet_run = '/usr/local/sbin/puppet-run'
  $puppet_cert_renew = '/usr/local/sbin/puppet-cert-renew'
  $registry = $::registry_url
  $solo = '/usr/local/bin/solo -port=58140'

  # con -i 5 ci riprova fino a 64 minuti dopo la chiamata, con 60 secondi
  # di -i ci riprova fino a 4h e mezzo dopo
  $puppet_run_cmd_dev = "${solo} ${puppet_run} -i 5 -q -m 2> /dev/null"
  $puppet_run_cmd_prod = "${solo} ${puppet_run} -i 60 -q -m 2> /dev/null"
  $augeas_lenses_dir = '/usr/share/augeas/lenses/dist'

  # Module defaults
  File {
    group   => 'admin',
    mode    => '0664',
  }

  Package {
    require => [ Class['apt'], Apt_puppetlabs::Source['puppetlabs'] ],
  }

  # clean old unused repository
  apt::source { 'puppet': ensure  => absent, }

  case $lsbdistcodename {
    'hardy' : {
      $puppet_env_version = $environment ? {
        'production'  => '2.7.18-1puppetlabs1',
        default       => '2.7.20~hardy~ppa1',
      }

      $facter_version = '1.6.18~lucid~ppa1'

      # for latest puppet, facter & augeas packages
      # Da questo repository prendiamo alcuni pacchetti di puppet,
      # tra cui libaugeas-ruby1.8 che è
      # rotto nel repo di puppetlabs per hardy e lucid
      softec_apt::ppa{'skettler/puppet':
        key     => 'C18789EA',
        mirror  => true
      }
    }

    'lucid': {
      $puppet_env_version = $environment ? {
        'production'  => '2.7.23-1puppetlabs1',
        default       => '2.7.23-1puppetlabs1',
      }

      $facter_version = '1.7.5-1puppetlabs1'

      # for latest facter & augeas packages
      # Da questo repository prendiamo alcuni pacchetti di puppet,
      # tra cui libaugeas-ruby1.8 che è
      # rotto nel repo di puppetlabs per hardy e lucid
      softec_apt::ppa {'skettler/puppet':
        mirror  => true,
        key     => 'C18789EA'
      }

    }

    default: {
      $puppet_env_version = $environment ? {
        'production'  => '2.7.23-1puppetlabs1',
        default       => '2.7.23-1puppetlabs1',
      }

      $facter_version = '1.7.5-1puppetlabs1'
    }
  }

  $puppet_version = $version ? {
    ''      => $puppet_env_version,
    default => $version
  }

  apt::source {'puppetlabs':
    location  => 'http://apt.puppetlabs.com',
    repos     => 'main',
    key       => '4BD6EC30',
  }

  if $::lsbdistcodename == 'precise' {
    # aggiungo questo ppa per precise che contiene augeas alla versione 1.0.0
    #apt::key { 'AE498453': }
    #apt::sources_list { 'augeas':
    #  content => "deb http://ppa.launchpad.net/raphink/augeas-1.0.0/ubuntu ${::lsbdistcodename} main\ndeb-src http://ppa.launchpad.net/raphink/augeas-1.0.0/ubuntu ${::lsbdistcodename} main",
    #}

    softec_apt::ppa {'raphink/augeas-1.0.0':
      key     => 'AE498453',
      #mirror  => true
    }
  }

  # INSTALL
  package {
    'augeas-lenses':        ensure => latest;
    'augeas-tools':         ensure => latest;
    'libaugeas-ruby':       ensure => latest;
    'libaugeas-ruby1.8':    ensure => latest;
    'rubygems':             ensure => latest;
    'libaugeas0':           ensure => latest;
  }

  apt::pin { 'puppet':
    packages  => [ 'puppet', 'puppet-common' ],
    version   => $puppet_version,
    priority  => '1001';
  'facter':
    packages  => 'facter',
    version   => $facter_version,
    priority  => '1001'
  } ->
  package {
    'puppet':               ensure => $puppet_version;
    'puppet-common':        ensure => $puppet_version;
    'facter':               ensure => $facter_version;
  }

  # CONFIG
  # TODO: chiarire a cosa serve questo qui
  # suppongo serva per il modulo SSH, ma da qui non si capisce
  # esplicitiamo la dipendenza con una define puppet::augeaslens{ 'ssh': } da mettere
  # nel modulo openssh. E magari con l'occasione tiriamo fuori augeas dal modulo puppet
  file { "${augeas_lenses_dir}/ssh.aug":
    ensure  => present,
    require => Package['augeas-lenses'],
    source  => 'puppet:///modules/puppet/ssh.aug',
  }

  file { '/var/log/puppet':
    ensure  => directory,
    group   => 'adm',
    mode    => '2770',
  }

  file { '/etc/default/puppet':
    ensure  => present,
    require => Package['puppet'],
  }

  # #569: disable running as a service
  exec { 'puppet-disable-startup':
    command     => '/bin/sed \'s/^START=yes/START=no/i\' -i~ /etc/default/puppet',
    unless      => '/bin/grep -q \'^START=no\' /etc/default/puppet',
    require     => File['/etc/default/puppet'],
  }

  #569: gestione di Puppet tramite cron, dovrebbe aver girato in
  # abbondanza su tutti i server
  # stop service if running
  # exec { "puppet-stop-service":
  #    command     => "echo /etc/init.d/puppet stop | at now + 15 minutes",
  #    onlyif      => "ps aux | grep -v grep | grep 'puppet agent$'",
  #    require     => Exec["puppet-disable-startup"],
  # }

  # Configurazione agent/master
  #file { "/etc/puppet/puppet.conf":
  #    ensure  => present,
  #    content => template("puppet/etc/puppet-master.conf.erb"),
  #}

  # Script that runs puppet until it exists whitout errors
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
      mode  => '0775',
      require => Package['puppet'];
    '/etc/puppet/etckeeper-commit-post':
      source  => 'puppet:///modules/puppet/etc/etckeeper-commit-post',
      mode  => '0775',
      require => Package['puppet'];
  }

  # da aggiungere??
  #"set agent/certname $fqdn",
  #"set agent/server $server",
  #"set agent/environment ${puppet_env}",
  augeas { 'puppet-agent-config':
    context => '/files/etc/puppet/puppet.conf',
    changes => [
      "set main/prerun_command /etc/puppet/etckeeper-commit-pre",
      "set main/postrun_command /etc/puppet/etckeeper-commit-post",
      "set main/pluginsync true", # non serve più da puppet 3.x
      "set agent/masterport 443",
      "set agent/pluginsync true", # non serve più da puppet 3.x
      "set agent/graph true",
      "set agent/graphdir /var/puppet",
      "set agent/report true"
    ],
    require => [
      File['/etc/puppet/etckeeper-commit-pre'],
      File['/etc/puppet/etckeeper-commit-post'],
      Package['puppet'],
    ],
  }

  case $environment {
    'production': {
      # in produzione, una volta tra le 11 e le 13 e una volta
      # tra le 14 e le 16, dal lunedi al giovedi compresi
      # Fx - sposto l'intervallo del mattino a 9-13
      # Fx - 13/02/2013 - tolgo l'esecuzione del puppet al pomeriggio

      $hour1 = fqdn_rand(2) + 09
      $hour2 = fqdn_rand(2) + 11
      $hour3 = fqdn_rand(2) + 13
      $minute = fqdn_rand(59)

      cron { 'puppet-cron-onetime':
        command => $puppet_run_cmd_prod,
        user    => 'root',
        weekday => [ 1,2,3,4 ],
        minute  => [ $minute ],
        hour    => [ $hour1, $hour2, $hour3 ],
        require => [
          File[ $puppet_run ],
          File['/var/log/puppet'],
          File['/usr/local/bin/solo']
          ],
      }
    }

    default: {
      # tutto ciò che non è produzione è sviluppo
      # una esecuzione ogni ora, tutti i giorni in 8-14
      $minute = fqdn_rand(59)

      cron { 'puppet-cron-onetime':
        command => $puppet_run_cmd_dev,
        user    => 'root',
        weekday => '*',
        minute  => [ $minute ],
        hour    => '8-14',
        require => [
          File[ $puppet_run ],
          File['/var/log/puppet'],
          File['/usr/local/bin/solo'] ],
      }
    }
  }

  $minute_renew = fqdn_rand(59)
  # rinnovo dei certificati
  cron { 'puppet-cert-renew':
    command => '/usr/local/sbin/puppet-cert-renew &> /dev/null',
    user    => 'root',
    weekday => '*',
    minute  => $minute_renew,
    hour    => '03',
    require => File['/usr/local/sbin/puppet-cert-renew']
  }

}
