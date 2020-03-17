#
# Class: puppet
#
class puppet (
  Integer[6]       $major_version = 6,
  Optional[String] $release       = undef,
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
    release      => $release,
    repos        => "puppet${major_version}",
    require      => File["/etc/apt/trusted.gpg.d/puppet${major_version}-keyring.gpg"],
  }
  package { "puppet${major_version}-release":
    require => Apt::Source["puppet${major_version}"],
  }
}
