forwarding_ports = node[:load_balancer][:forwarding_ports].split(',').reject{|port| port == '443'}
forwarding_ports.each do |port|
  listener_name = "#{node[:load_balancer][:prefix]}#{port}"
  bash 'Registering instance with haproxy configuration' do
    code <<-EOF
      echo disconnecting instance: #{node[:load_balancer][:instance_backend_name]}, with listener: #{listener_name} from haproxy

      script="/opt/rightscale/lb/bin/haproxy_config_server.rb"
      args="-a add -w -s #{node[:load_balancer][:instance_backend_name]} -l #{listener_name} -t #{node[:load_balancer][:instance_ip]} -e \"inter 3000 rise 2 fall 3 maxconn #{node[:max_connections_per_lb]}\" -k on"

      /opt/rightscale/sandbox/bin/ruby $script $args
    EOF
  end
end
