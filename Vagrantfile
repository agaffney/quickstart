Vagrant.configure("2") do |config|
  config.vm.box = "generic/gentoo"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "Quickstart"
    vb.memory = 1024
    vb.cpus = 2
    vb.linked_clone = true if Vagrant::VERSION =~ /^1.8/

    # Get disk path
    line = `VBoxManage list systemproperties`.split(/\n/).grep(/Default machine folder/).first
    vb_machine_folder = line.split(':', 2)[1].strip()
    install_disk = File.join(vb_machine_folder, vb.name, 'disk2.vdi')

    # Create new disk
    unless File.exist?(install_disk)
      vb.customize ['createhd', '--filename', install_disk,
                    '--format', 'VDI', '--size', 60 * 1024]
    end

    # Attach new disk
    vb.customize ['storageattach', :id,
                  '--storagectl', 'IDE Controller',
                  '--port', 0, '--device', 1,
                  '--type', 'hdd', '--medium', install_disk]

  end

  config.vm.provision "shell", inline: <<-SHELL
    sudo emerge -nq dev-vcs/git \
                    net-fs/sshfs # needed for vagrant-sshfs plugin
  SHELL

  config.vm.synced_folder ".", "/usr/src/quickstart", type: "sshfs", reverse: false

end
