#
class puppet::agent (
  String           $environment  = 'production',
  Boolean          $managed      = true,
  Optional[String] $cron_wrapper = undef,
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

  # sudo's secure_path doesn't include /opt/puppetlabs/puppet/bin
  # add this symlink to make this work: sudo puppet agent -t
  file { '/usr/local/bin/puppet':
    ensure  => link,
    target  => '/opt/puppetlabs/puppet/bin/puppet',
    require => Package['puppet-agent'],
  }

  if $facts['aio_agent_version'] {
    if $cron_wrapper {
      $cron_command = $cron_wrapper
    } else {
      $cron_command = '/opt/puppetlabs/puppet/bin/puppet agent --onetime --no-daemonize'
    }
    if $managed {
      $cron_ensure = 'present'
    } else {
      $cron_ensure = 'absent'
    }

    # AIO puppet.conf path
    $conf_path = '/etc/puppetlabs/puppet/puppet.conf'

    # error out when there is an unbound variable
    ini_setting { 'puppet.conf/main/strict_variables':
      ensure  => present,
      path    => $conf_path,
      section => 'main',
      setting => 'strict_variables',
      value   => true,
    }
    # disable i18n
    ini_setting { 'puppet.conf/main/disable_i18n':
      ensure  => present,
      path    => $conf_path,
      section => 'main',
      setting => 'disable_i18n',
      value   => true,
    }
  } else {
    # XXX: the legacy client/wrapper script is used one last time to make the transition
    #      to the AIO/upstream client
    $cron_command = '[ -x /etc/puppet/puppet-agent.sh ] && /etc/puppet/puppet-agent.sh'
    $cron_ensure = 'present'

    file { '/etc/puppet/puppet-agent.sh':
      mode   => '0755',
      source => 'puppet:///modules/puppet/puppet-agent.sh.transition',
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
