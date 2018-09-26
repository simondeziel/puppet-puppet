#
# Class: puppet
#
class puppet (
  Integer[5,6] $major_version = 6,
) {
  # XXX: same as:
  #  wget https://apt.puppetlabs.com/puppet${major_version}-release-${::lsbdistcodename}.deb
  #  dpkg -i puppet${major_version}-release-${::lsbdistcodename}.deb
  file { "/etc/apt/trusted.gpg.d/puppet${major_version}-keyring.gpg":
    ensure => file,
    source => "puppet:///modules/puppet/puppet${major_version}-keyring.gpg",
  }
  apt::source { "puppet${major_version}":
    architecture => 'amd64',
    location     => 'http://apt.puppetlabs.com',
    repos        => "puppet${major_version}",
    require      => File["/etc/apt/trusted.gpg.d/puppet${major_version}-keyring.gpg"],
  }
  package { "puppet${major_version}-release":
    require => Apt::Source["puppet${major_version}"],
  }

  if $major_version >= 6 {
    package { 'puppet5-release':
      ensure  => purged,
      require => Package["puppet${major_version}-release"],
    }
  }
}
