# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu/trusty64"

  # Provider-specific configuration
  config.vm.provider "virtualbox" do |vb|
    # Up the memory to 1 gig
    vb.customize ["modifyvm", :id, "--memory", "1024"]
  end

  # Provision with Bash script
  config.vm.provision :shell, :privileged => false, :path => "bootstrap.sh"
end
