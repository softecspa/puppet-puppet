# == define puppet::master::mount
#
# Configure puppetmaster fileserver.conf
#
# === Params
#
# [*ensure*]
#   Specifies if conf should be present (default: present)
#
# [*path*]
#   directory to configure
#
# [*allow*]
#   allow policy (default *)
#
# [*deny*]
#   deny policy (default: false)
#
# === Examples
#
define puppet::master::mount(
  $ensure=present,
  $path,
  $allow='*',
  $deny=false,
){

  if !defined(Concat['/etc/puppet/fileserver.conf']) {
    fail "Missing concat main call"
  }

  file { $path:
    ensure  => directory,
    group   => admin,
    mode    => 02775,
  }

  concat::fragment{"puppetmaster mountpoint $title":
    target  => '/etc/puppet/fileserver.conf',
    content => template('puppet/etc/fileserver_mountpoint.erb'),
  }

}
