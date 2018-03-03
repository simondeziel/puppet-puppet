#
class puppet::agent (
  String  $environment = 'production',
  Boolean $managed     = true,
  Boolean $upstream    = false,
) {
  if $upstream or $facts['aio_agent_version'] {
    $cron_command = '/opt/puppetlabs/puppet/bin/puppet agent --onetime --no-daemonize'

    include puppet
    package { 'puppet-agent':
      ensure  => installed,
      require => Class['puppet'],
    }
  } else {
    $cron_command = '[ -x /etc/puppet/puppet-agent.sh ] && /etc/puppet/puppet-agent.sh'

    file { '/etc/puppet/puppet.conf':
      content => epp('sdeziel/puppet/puppet.conf.epp'),
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
    }
    file { '/etc/puppet/puppet-agent.sh':
      mode    => '0755',
      source  => 'puppet:///modules/sdeziel/puppet/puppet-agent.sh',
    }
  }

  if $managed {
    $cron_ensure = 'present'
  } else {
    $cron_ensure = 'absent'
  }
  cron { 'puppet-agent':
    ensure   => $cron_ensure,
    user     => 'root',
    command  => $cron_command,
    minute   => fqdn_rand(60),
    hour     =>  [0, 2, '6-18', 22],
    monthday => '*',
    month    => '*',
    weekday  => '*',
  }
}
