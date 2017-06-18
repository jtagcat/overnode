#
# License: https://github.com/webintrinsics/clusterlite/blob/master/LICENSE
#

#
# load machines specification
#
require 'yaml'
curr_dir  = File.dirname(File.expand_path(__FILE__))
machines    = YAML.load_file("#{curr_dir}/Vagranthosts.yaml")

#
# assert vagrant setup
#
Vagrant.require_version '>= 1.8.6', '!= 1.8.5'
def validate_plugins
  required_plugins = [
    'vagrant-hostmanager',
    'vagrant-proxyconf'
  ]
  missing_plugins = []

  required_plugins.each do |plugin|
    unless Vagrant.has_plugin?(plugin)
      missing_plugins << "The '#{plugin}' plugin is required. Install it with 'vagrant plugin install #{plugin}'"
    end
  end

  unless missing_plugins.empty?
    missing_plugins.each { |x| STDERR.puts x }
    return false
  end

  true
end

validate_plugins || exit(1)

#
# Provision machines
#
first_master = ''
Vagrant.configure(2) do |config|

  # configure vagrant-hostmanager plugin to place correct /etc/hosts files
  # https://github.com/devopsgroup-io/vagrant-hostmanager
  config.hostmanager.enabled = true
  #config.hostmanager.manage_host = true # updates hosts file for current host, requires admin
  config.hostmanager.ignore_private_ip = false

  machines.each do |name, machine|
    config.vm.define name do |s|
        s.vm.box = machine['box'] || "bento/ubuntu-16.04"
        s.ssh.forward_agent = true

        #
        # configure networking for VM
        #
        s.vm.hostname = "#{name}.clusterlite.local"
        aliases = [name]
        if machine['aliases']
          aliases.push(*machine['aliases'])
        end
        s.hostmanager.aliases = aliases.join(' ').to_s
        s.vm.network "private_network", ip: machine['ip'], netmask: "255.255.255.0", auto_config: true
        if machine.has_key?('forwarded_port')
            s.vm.network "forwarded_port", guest: (machine['forwarded_port']['guest'] || 80), host: (machine['forwarded_port']['host'] || 80)
        end
        s.vm.provider "virtualbox" do |v|
            v.name = s.vm.hostname
            v.cpus = machine['cpus'] || 2
            v.memory = machine['memory'] || 2048
            v.gui = false

            # disable DHCP client configuration for NAT interface
            v.auto_nat_dns_proxy = false
            v.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
            v.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
        end
        # Remove loopback host alias that conflicts with vagrant-hostmanager
        # https://dcosjira.atlassian.net/browse/VAGRANT-15
        s.vm.provision :shell, inline: "sed -i'' '/^127.0.0.1\\t#{s.vm.hostname}\\t#{name}$/d' /etc/hosts"
        # configure proxy settings
        if ENV.has_key?('http_proxy') || ENV.has_key?('HTTP_PROXY')
            s.proxy.http = ENV['http_proxy'] || ENV['HTTP_PROXY']
            s.proxy.https = ENV['http_proxy'] || ENV['HTTP_PROXY']
        end
        if ENV.has_key?('https_proxy') || ENV.has_key?('HTTPS_PROXY')
            s.proxy.https = ENV['https_proxy'] || ENV['HTTPS_PROXY']
        end
        if ENV.has_key?('no_proxy') || ENV.has_key?('NO_PROXY')
            s.proxy.no_proxy = ENV['no_proxy'] || ENV['NO_PROXY']
        end

        #
        # set toogle for development mode
        #
        if ENV.has_key?('development_mode') || ENV.has_key?('DEVELOPMENT_MODE') || true # disable development mode later
            s.vm.provision :shell, inline: "echo \"export DEVELOPMENT_MODE=true\" >> ~/.profile"
        end

        #
        # for ubuntu install the fastest mirror
        # http://askubuntu.com/questions/39922/how-do-you-select-the-fastest-mirror-from-the-command-line
        #
        s.vm.provision :shell, inline: "cp /vagrant/mirror.list /etc/apt/sources.list.d/mirror.list"

        #
        # provision
        #
        machine['provision'].each do |command|
            s.vm.provision :shell, inline: "#{command}"
        end
    end
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

end
