# == class puppet::master::code
#
#  Download and configure all repositories (Softec and third-party) for Puppet
#
# === Params
#
# === Examples
#
class puppet::master::code (
  $autoupdate  = true
){

  file {
    '/etc/puppet/envs/development':  ensure  => directory;
  }

  subversion::checkout { 'checkout of puppet trunk (dev)':
    ensure              => 'updated',
    method              => $::svn_method,
    host                => $::svn_host,
    svnuser             => $::svn_user,
    password            => $::svn_password,
    repopath            => '/sistemi/puppet/trunk',
    workingdir          => '/etc/puppet/envs/development',
    require             => File['/etc/puppet/envs/development'],
  }

  augeas { 'master-envs-dev':
    context => '/files/etc/puppet/puppet.conf',
    changes => [
      "set development/manifest /etc/puppet/envs/development/manifests/site.pp",
      "set development/modulepath /etc/puppet/envs/development/modules:/usr/share/puppet/modules",
    ]
  }

  class {'puppet::master::gh':
    autoupdate  => $autoupdate,
  }

  class {'puppet::master::private_modules':
    autoupdate  => $autoupdate,
  }

}
