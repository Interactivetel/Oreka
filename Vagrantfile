# -*- mode: ruby -*-
# vi: set ft=ruby :

# $version = :unknown
# case RUBY_PLATFORM
#   when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
#     $version = :windows
#   when /darwin|mac os/
#     $version = :macosx
#   when /linux/
#     $version = :linux
#   when /solaris|bsd/
#     $version = :unix
# end

Vagrant.configure("2") do |config|

  config.vbguest.auto_update = false
  config.vm.provider "virtualbox" do |vb, override|
    vb.gui = false
    vb.cpus = 4
    vb.memory = 4096
    vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
  
    # network configuration (use the default network interface in the host for the bridge)
    # if $version == :macosx then
    #   default_iface = `route get example.com | grep interface`.split(":")[1].strip()
    # else
    #   default_iface = `ip route | awk '/^default/ {printf "%s", $5; exit 0}'`.strip()
    # end
  
    # host_ifaces = `VBoxManage list bridgedifs | grep ^Name`.gsub(/Name:\s+/, '').split("\n")
    # bridge_iface = host_ifaces.find {|i| i.include?(default_iface)}
    # override.vm.network "public_network", bridge: $bridge_iface
  end
  

  config.vm.define "centos6", primary: true do |centos6|
    centos6.vm.box = "generic/centos6"
    centos6.vm.hostname = "CentOS6-OrkAudio"
    centos6.vm.provider "virtualbox" do |vb|
      vb.name = centos6.vm.hostname
    end
  end

  config.vm.define "debian11" do |debian11|
    debian11.vm.box = "generic/debian11"
    debian11.vm.hostname = "Debian11-OrkAudio"
    debian11.vm.provider "virtualbox" do |vb|
      vb.name = debian11.vm.hostname
    end
  end

  config.vm.synced_folder ".", "/home/vagrant/Oreka", type: "virtualbox"
end
