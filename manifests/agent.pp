#
class puppet::agent (
  String           $cron_command        = 'exec /opt/puppetlabs/puppet/bin/puppet agent --onetime --no-daemonize',
  Array[String]    $cron_hours          = ['0','2','6-18','22'],
  Optional[String] $cron_script_content = undef,
  Optional[String] $cron_script_file    = undef,
  String           $environment         = 'production',
  Boolean          $managed             = true,
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
  # lower priority
  ini_setting { 'puppet.conf/main/priority':
    ensure  => present,
    path    => $conf_path,
    section => 'main',
    setting => 'priority',
    value   => '10',
  }

  $cron_ensure = $managed ? {
    true    => 'present',
    default => 'absent',
  }

  if $managed and $cron_script_file {
    if ! $cron_script_content {
      fail('Missing cron_script_content for managed agent')
    }

    file { $cron_script_file:
      ensure  => $cron_ensure,
      content => $cron_script_content,
      mode    => '0755',
      before  => Cron['puppet-agent'],
    }
  }

  cron { 'puppet-agent':
    ensure   => $cron_ensure,
    user     => 'root',
    command  => $cron_command,
    minute   => fqdn_rand(60),
    hour     => $cron_hours,
    monthday => '*',
    month    => '*',
    weekday  => '*',
  }
}
