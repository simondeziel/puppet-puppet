#
# Class: puppet
#
class puppet {
  # XXX: same as:
  #  wget https://apt.puppetlabs.com/puppet5-release-${::lsbdistcodename}.deb
  #  dpkg -i puppet5-release-${::lsbdistcodename}.deb
  file { '/etc/apt/trusted.gpg.d/puppet5-keyring.gpg':
    ensure => file,
    source => 'puppet:///modules/puppet/puppet5-keyring.gpg',
  }
  apt::source { 'puppet5':
    architecture => 'amd64',
    location     => 'http://apt.puppetlabs.com',
    repos        => 'puppet5',
    #key          => {
    #  'id'     => '6F6B15509CF8E59E6E469F327F438280EF8D349F',
    #  'url'    => 'https://apt.puppetlabs.com/DEB-GPG-KEY-puppet',
    #},
    require      => File['/etc/apt/trusted.gpg.d/puppet5-keyring.gpg'],
  }
}
