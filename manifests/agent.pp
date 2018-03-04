#
class puppet::agent (
  String  $environment = 'production',
  Boolean $managed     = true,
) {
  include puppet
  package { 'puppet-agent':
    ensure  => installed,
    require => [Class['puppet'],Exec['apt_update']],
  }

  # run the puppet agent from cron to save on RAM
  # and not using mcollective (yet)
  service { ['puppet','mcollective']:
    ensure  => stopped,
    enable  => false,
    require => Package['puppet-agent'],
  }

  if $facts['aio_agent_version'] {
    $cron_command = '/opt/puppetlabs/puppet/bin/puppet agent --onetime --no-daemonize'
    if $managed {
      $cron_ensure = 'present'
    } else {
      $cron_ensure = 'absent'
    }
  } else {
    # XXX: the legacy client/wrapper script is used one last time to make the transition
    #      to the AIO/upstream client
    $cron_command = '[ -x /etc/puppet/puppet-agent.sh ] && /etc/puppet/puppet-agent.sh'
    $cron_ensure = 'present'

    file { '/etc/puppet/puppet-agent.sh':
      mode    => '0755',
      source  => 'puppet:///modules/puppet/puppet-agent.sh.transition',
    }
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
