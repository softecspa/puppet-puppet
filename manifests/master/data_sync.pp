# == class puppet::master::data_sync
#
#  Sync S3 bucket for puppetmaster
#
# === Params
#
# === Examples
#
class puppet::master::data_sync {
  # Sync local files

  puppet::master::s3sync{ 'Puppetmaster --> S3: keys':
    datatype => 'keys',
  }

  puppet::master::s3sync{ 'Puppetmaster --> S3: ssl':
    datatype => 'ssl',
  }

  puppet::master::s3sync{ 'Puppetmaster --> S3: yaml':
    datatype => 'yaml',
  }
}