# == class puppet::master::gh
#
#  Downloads specific projects from Softec's GH account
#
# === Params
#
# === Examples
#
class puppet::master::private_modules (
  $autoupdate,
  $private_repos,
  $private_repos_author,
){
  # all repos reside on softec account

  $private_modules = [
    'sslcert',
    'ispconfig_cluster',
    'ispconfig_files',
    'ispconfig_master',
    'ispconfig_slave',
    'ispconfig_tomcat',
    'tomcat',
    'ispconfig_mirror',
    'varnish',
    'softec_registry',
    'sia',
    'softec_private',
    'skeleton',
    'onepub',
    'drupal',
    'accounts',
    'generic_account',
    'antandra_app',
    'softec_apache'
  ]

  puppet::master::module { $private_modules:
    updated => $autoupdate,
    author  => $private_repos_author,
    server  => $private_repos,
    method  => 'ssh',
  }
}
