Vagrant::Config.run do |config|
  config.vm.box = "centos6.4"
  config.vbguest.auto_update = true
  Vagrant::Config.run do |config|
    config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = ["~/personal/cookbooks"]
      chef.add_recipe "elasticsearch"
    end
  end
end
