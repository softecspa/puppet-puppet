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
  ]

  puppet::master::module { $private_modules:
    author    => $puppet::master::private_repos_author,
    server    => $puppet::master::private_repos,
    method    => 'ssh',
    identity  => $puppet::master::private_repos_key
  }
}
