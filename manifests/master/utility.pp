class puppet::master::utility {
  file { 'puppet-create-tag':
    path    => '/usr/local/sbin/puppet-create-tag',
    owner   => 'root',
    group   => 'admin',
    mode    => '0750',
    content => template('puppet/puppet-create-tag.erb')
  }

  file { 'puppet-update-prod':
    path    => '/usr/local/sbin/puppet-update-prod',
    owner   => 'root',
    group   => 'admin',
    mode    => '0750',
    content => template('puppet/puppet-update-prod.erb')
  }

  file { 'puppet-production-conf':
    path    => '/usr/local/sbin/puppet-production-conf',
    owner   => 'root',
    group   => 'admin',
    mode    => '0750',
    content => template('puppet/puppet-production-conf.erb')
  }

  file { 'puppet-motd':
    path    => '/etc/update-motd.d/60-puppetmaster',
    owner   => 'root',
    group   => 'admin',
    mode    => '0755',
    content => template('puppet/puppet-motd.erb')
  }

  file {
    '/etc/profile.d/puppet.sh':
      source  => 'puppet:///modules/puppet/etc/profile.d_puppet',
      mode    => '0755';
    '/usr/local/sbin/puppet-cert-generate':
      source  => 'puppet:///modules/puppet/sbin/puppet-cert-generate',
      mode    => '0775';
    '/usr/local/sbin/puppet-cert-clean':
      source  => 'puppet:///modules/puppet/sbin/puppet-cert-clean',
      mode    => '0775';
    '/usr/local/sbin/puppet-lock-renew':
      source  => 'puppet:///modules/puppet/sbin/puppet-lock-renew',
      mode    => '0775';
  }

  file {'/var/run/lock/registry':
    ensure  => directory,
    mode    => '0755',
    owner   => 'puppet'
  }
}
