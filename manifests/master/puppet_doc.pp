# == class puppet::master::doce
#
# Schedule Puppet Doc creation and publish the relative vhost
#
class puppet::master::puppet_doc {
  file {
    '/usr/local/sbin/puppet-make-doc':
      source  => 'puppet:///modules/puppet/sbin/puppet-make-doc',
      mode    => '0755';
  }

  cron::customentry { 'puppet-doc':
    special => 'hourly',
    command => '/usr/local/sbin/puppet-make-doc',
  }

  $web_dirs = ['/var/www/puppet-doc.tools.softecspa.it',
              '/var/www/puppet-doc.tools.softecspa.it/web']

  file { $web_dirs:
    ensure  => directory;
  } ->

  apache::vhost { 'puppet-doc.tools.softecspa.it':
    listen  => '80',
    docroot => '/var/www/puppet-doc.tools.softecspa.it/web'
  }

}
