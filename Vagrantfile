# -*- mode: ruby -*-
# vi: set ft=ruby :

# Provisioning script
$script = <<SCRIPT
  echo "*** Updating packages"

  sudo apt-get update
  sudo apt-get -y upgrade

  echo "*** Installing new packages"
  sudo apt-get install -y curl git-core memcached vim zip zlib1g-dev cmake sqlite3

  echo "*** Installing rbenv"
  sudo apt-get install -y rbenv
  rbenv init
  echo "gem: --no-document" > ~/.gemrc

  echo "*********************"
  echo "PROVISIONING FINISHED"
  echo "*********************"
SCRIPT


Vagrant.configure('2') do |config|
  config.vm.box      = "ubuntu/focal64"
  config.vm.hostname = "tinycrm"
  config.vm.network :forwarded_port, guest: 9001, host: 9001

  # Provision the machine with the shell script above
  config.vm.provision "shell", inline: $script, privileged: false
  config.ssh.extra_args = ["-t", "cd /vagrant; bash --login"]

  # Performance optimizations
  config.vm.provider "virtualbox" do |v|
    # Set the timesync threshold to 5 seconds, instead of the default 20 minutes.
    v.customize ["guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 5000]
  end
end
