define puppet::master::checkout_data{
  puppet::master::s3sync{ 'Softec puppetmaster: keys':
    datatype => 'keys',
    reverse => true,
  }

  puppet::master::s3sync{ 'Softec puppetmaster: ssl':
    datatype => 'ssl',
    reverse => true,
  }

  puppet::master::s3sync{ 'Softec puppetmaster: yaml':
    datatype => 'yaml',
    reverse => true,
  }
}