define puppet::master::s3sync (
  $datatype = 'ssl',
  $reverse = false,
) {

  if ! defined(Class["s3cmd"]) {
    class {"s3cmd":
      access_key  => $::aws_access_key,
      secret_key  => $::aws_secret_key,
    }
  }

  s3cmd::sync {"sync-puppetmaster-${datatype}-with-s3":
    source      => "/var/lib/puppet/${datatype}/",
    bucket_name => 'softec-puppetmaster',
    prefix      => "${datatype}/",
    reverse     => $reverse,
    require     => Class['s3cmd'],
  }
 
}