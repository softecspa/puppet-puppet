# == define puppet::master::module
#
# Install a puppet module from github://$author/$repo
#
# Author and Repository can be explicitly specified
# or deducted from module name.
#
# === Params
#
# [*prefix*]
#   Puppet modules are commonly named puppet-something, module name should be
#   specified without this prefix (default: puppet)
#
# [*author*]
#   the github account where the module reside; if empty the author name MUST
#   be specified in the resource name, in the format author/module-name
#
# [*modname*]
#   name of the puppet module to install: this will be the name of the
#   directory where module code is cloned.
#
# [*target*]
#   name of the directory to which clone the module, if undef modname
#   will be choosen (default: undef)
#
# [*target_path*]
#   target path in which clone
#   If undefined will use $puppet::master:shared_modulepath
#
# [*updated*]
#   keep the repo updated (Default: false)
#
# === Examples
#
# 1. clone from github/lorello/puppet-nginx in a directory 'nginx'
#
#   puppet::master::module{ 'lorello/nginx': }
#
# 2. clone from github/puppetlabs/puppetlabs-stdlibs in a directory 'stdlibs'
#
#   puppet::master::module{ 'stdlibs':
#     prefix => 'puppetlabs',
#     author => 'puppetlabs',
#   }
#
# 3. clone from github/karen/puppet-sudo in a directory 'sudo'
#
#   puppet::master::module { 'karen/sudo': }
#
# equivalent to
#
#   puppet::master::module { 'sudo':
#     author => 'karen',
#   }
#
# 4. clone module from github/example42/puppi in a directory 'puppi'
#
#   puppet::master::module { 'puppi':
#     prefix => '',
#     author => 'example42',
#   }
#
# equivalent to
#
#   puppet::master::module { 'example42/puppi':
#     prefix => '',
#   }
#
define puppet::master::module (
  $prefix = 'puppet',
  $author = undef,
  $modname = undef,
  $target = undef,
  $target_path = undef,
  $updated = false,
  $server = 'github.com',
  $auth_user = undef,
  $auth_pass = undef,
  $method     = 'https',
  $identity = undef
)
{
  $target_path_ = $target_path ? {
    undef     => $puppet::master::shared_modulepath,
    default   => $target_path,
  }

  if $author == undef {
    validate_re($name, '[A-Za-z0-9]+/[A-Za-z0-9]+',
                'name of the resource must be in the format USER/REPOSITORY')
    $name_array = split($name, '/')
    validate_array($name_array)

    $real_user = $name_array[0]
    $mod_name = $name_array[1]

  } else {
    $real_user  = $author
    $mod_name = $name
  }

  $real_modname = $modname ? {
    undef     => $mod_name,
    default   => $modname,
  }

  if $prefix == '' {
    $real_repo = $real_modname
  } else {
    $real_repo = "${prefix}-${real_modname}"
  }

  $target_ = $target ? {
    undef     => $real_modname,
    default   => $target,
  }

  $ensure_vcsrepo = $updated? {
    true  => 'latest',
    false => 'present'
  }

  $revision_vcsrepo = $updated? {
    true  => 'master',
    false => undef
  }

  $source_url = $method?{
    'https' => "https://${server}/${real_user}/${real_repo}.git",
    'ssh'   => "git@${server}:${real_user}/${real_repo}.git"
  }

  vcsrepo { "${target_path_}/${target_}":
    ensure              => $ensure_vcsrepo,
    provider            => git,
    source              => $source_url,
    revision            => $revision_vcsrepo,
    identity            => $identity
  }

  #git::clone{ "clone-$name":
  #  url   => "https://github.com/${real_user}/${real_repo}.git",
  #  path  => "${target_path_}/${target_}",
  #}

  #if $updated {
  #  git::pull{ "pull-$name":
  #    path  => "${target_path_}/${target_}",
  #  }
  #}

}
