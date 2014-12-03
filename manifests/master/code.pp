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
  $autoupdate           = true,
){

  file {
    '/etc/puppet/envs/development':  ensure  => directory;
    '/etc/puppet/envs/production':   ensure  => directory;
  }

  #subversion::checkout { 'checkout of puppet trunk (dev)':
  #  ensure              => 'updated',
  #  method              => $::svn_method,
  #  host                => $::svn_host,
  #  svnuser             => $::svn_user,
  #  password            => $::svn_password,
  #  repopath            => '/sistemi/puppet/trunk',
  #  workingdir          => '/etc/puppet/envs/development',
  #  require             => File['/etc/puppet/envs/development'],
  #}

  augeas { 'master-envs-dev':
    context => '/files/etc/puppet/puppet.conf',
    changes => [
      "set development/manifest /etc/puppet/envs/development/manifests/site.pp",
      "set development/modulepath /etc/puppet/envs/development/modules:/usr/share/puppet/modules",
    ]
  }

  if $autoupdate {
    $vcsrepo_ensure   = 'latest'
    $vcsrepo_revision = 'master'
  } else {
    $vcsrepo_ensure = 'present'
    $vcsrepo_revision = undef
  }

  #file necessario alla autenticazione su gitlab
  file {'/root/.netrc':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => "machine ${private_repos}\nlogin ${private_repos_user}\npassword ${private_repos_pass}"
  }

  vcsrepo {'/etc/puppet/envs/development/manifests':
    ensure    => $vcsrepo_ensure,
    provider  => git,
    source    => "https://${private_repos}/${private_repos_author}/puppet-manifests.git",
    revision  => 'development',
    require   => [
      File['/etc/puppet/envs/development'],
      File['/root/.netrc']
    ]
  }

  vcsrepo {'/etc/puppet/envs/production/manifests':
    ensure    => $vcsrepo_ensure,
    provider  => git,
    source    => "https://${private_repos}/${private_repos_author}/puppet-manifests.git",
    revision  => 'master',
    require   => [
      File['/etc/puppet/envs/development'],
      File['/root/.netrc']
    ]
  }

  vcsrepo {'/etc/puppet/nodes':
    ensure    => $vcsrepo_ensure,
    provider  => git,
    source    => "https://${private_repos}/${private_repos_author}/puppet-nodes.git",
    revision  => $vcsrepo_revision,
    require   => File['/root/.netrc']
  }

  vcsrepo {'/etc/puppet/roles':
    ensure    => $vcsrepo_ensure,
    provider  => git,
    source    => "https://${private_repos}/${private_repos_author}/puppet-roles.git",
    revision  => $vcsrepo_revision,
    require   => File['/root/.netrc']
  }

  vcsrepo {'/etc/puppet/hiera':
    ensure    => $vcsrepo_ensure,
    provider  => git,
    source    => "https://${private_repos}/${private_repos_author}/puppet-hiera.git",
    revision  => $vcsrepo_revision,
    require   => File['/root/.netrc']
  }

  class {'puppet::master::gh':
    autoupdate  => $autoupdate,
  }

  class {'puppet::master::private_modules':
    autoupdate            => $autoupdate,
    private_repos         => $private_repos,
    private_repos_author  => $private_repos_author,
    require               => File['/root/.netrc']
  }

}
