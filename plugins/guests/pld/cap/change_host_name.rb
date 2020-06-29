require 'vagrant/util/guest_hosts'

module VagrantPlugins
  module GuestPld
    module Cap
      class ChangeHostName
        extend Vagrant::Util::GuestHosts::Linux

        def self.change_host_name(machine, name)
          comm = machine.communicate

          network_with_hostname = machine.config.vm.networks.map {|_, c| c if c[:hostname] }.compact[0]
          if network_with_hostname
            replace_host(comm, name, network_with_hostname[:ip])
          else
            add_hostname_to_loopback_interface(comm, name)
          end
          
          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split(".", 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              hostname '#{name}'
              sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/sysconfig/network

              sed -i 's/\\(DHCP_HOSTNAME=\\).*/\\1\"#{name}\"/' /etc/sysconfig/interfaces/ifcfg-*

              # Restart networking
              service network restart
            EOH
          end
        end
      end
    end
  end
end
