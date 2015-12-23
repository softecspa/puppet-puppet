# == class puppet::master::code
#
#  Download and configure all repositories (Softec and third-party) for Puppet
#
# === Params
#
# === Examples
#
class puppet::master::code (
  $private_repos,
  $private_repos_author,
  $private_repos_user,
  $private_repos_pass,
  $autoupdate = true,) {
  file {
    '/etc/puppet/environments/development':
      ensure => directory;

    '/etc/puppet/environments/production':
      ensure => directory;
  }

  #augeas { 'master-environments-dev':
  #  context => '/files/etc/puppet/puppet.conf',
  #  changes => [
  #    'set development/manifest /etc/puppet/environments/development/manifests/site.pp',
  #    'set development/modulepath /etc/puppet/environments/development/modules:/usr/share/puppet/modules',
  #    ]
  #}

  if $autoupdate {
    $vcsrepo_ensure = 'latest'
    $vcsrepo_revision = 'master'
  } else {
    $vcsrepo_ensure = 'present'
    $vcsrepo_revision = undef
  }

  # file necessario alla autenticazione su gitlab
  file { '/root/.netrc':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => "machine ${private_repos}\nlogin ${private_repos_user}\npassword ${private_repos_pass}"
  }

  vcsrepo { '/etc/puppet/environments/development/manifests':
    ensure   => $vcsrepo_ensure,
    provider => git,
    source   => "https://${private_repos}/${private_repos_author}/puppet-manifests.git",
    revision => 'development',
    require  => [
      File['/etc/puppet/environments/development'],
      File['/root/.netrc']]
  }

  vcsrepo { '/etc/puppet/environments/production/manifests':
    ensure   => $vcsrepo_ensure,
    provider => git,
    source   => "https://${private_repos}/${private_repos_author}/puppet-manifests.git",
    revision => 'master',
    require  => [
      File['/etc/puppet/environments/development'],
      File['/root/.netrc']]
  }

  vcsrepo { '/etc/puppet/nodes':
    ensure   => $vcsrepo_ensure,
    provider => git,
    source   => "https://${private_repos}/${private_repos_author}/puppet-nodes.git",
    revision => $vcsrepo_revision,
    require  => File['/root/.netrc']
  }

  vcsrepo { '/etc/puppet/roles':
    ensure   => $vcsrepo_ensure,
    provider => git,
    source   => "https://${private_repos}/${private_repos_author}/puppet-roles.git",
    revision => $vcsrepo_revision,
    require  => File['/root/.netrc']
  }

  vcsrepo { '/etc/puppet/hieradata':
    ensure   => $vcsrepo_ensure,
    provider => git,
    source   => "https://${private_repos}/${private_repos_author}/puppet-hiera.git",
    revision => $vcsrepo_revision,
    require  => File['/root/.netrc']
  }

  class { 'puppet::master::gh':
    autoupdate => $autoupdate,
  }

  class { 'puppet::master::private_modules':
    autoupdate           => $autoupdate,
    private_repos        => $private_repos,
    private_repos_author => $private_repos_author,
    require              => File['/root/.netrc']
  }

}
