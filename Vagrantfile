# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
    :repo => {
        :box_name => "almalinux/9",
        :ip_addr => '192.168.50.10',
        :script => 'rpm_repo_create.sh',
        :cpus => 1,
        :memory => 512,
    },
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
      config.vm.define boxname do |box|
          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s + ".test.local"
          box.vm.network "private_network", ip: boxconfig[:ip_addr], virtualbox__intnet: "net1"
          box.vm.provider :virtualbox do |vb|
            vb.memory = boxconfig[:memory]
            vb.cpus = boxconfig[:cpus] 	        
          end
          box.vm.provision "shell", path: boxconfig[:script]
      end
  end
end
