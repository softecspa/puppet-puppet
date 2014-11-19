# == class puppet::master::code
#
#  Download and configure all repositories (Softec and third-party) for Puppet
#
# === Params
#
# === Examples
#
class puppet::master::code (
  $autoupdate           = true,
  $private_repos        = undef,
  $private_repos_author = undef,
  $private_repos_key    = undef,
){

  file {
    '/etc/puppet/envs/development':  ensure  => directory;
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

  vcsrepo {'/etc/puppet/nodes':
    ensure    => $vcsrepo_ensure,
    provider  => git,
    source    => "git@${private_repos}:${private_repos_author}/puppet-nodes.git",
    revision  => $vcsrepo_revision,
    identity  => $private_repos_key
  }

  vcsrepo {'/etc/puppet/roles':
    ensure    => $vcsrepo_ensure,
    provider  => git,
    source    => "git@${private_repos}:${private_repos_author}/puppet-roles.git",
    revision  => $vcsrepo_revision,
    identity  => $private_repos_key
  }

  class {'puppet::master::gh':
    autoupdate  => $autoupdate,
  }

  if $private_repos and $private_repos_author and $private_repos_key {
    class {'puppet::master::private_modules':
      autoupdate            => $autoupdate,
      private_repos         => $private_repos,
      private_repos_author  => $private_repos_author,
      private_repos_key     => $private_repos_key,
    }
  }

}
