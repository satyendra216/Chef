ruby_block "Register web server with HAProxy" do
  block do
    puts "running register web server with haproxy"

    require 'yaml'
    require 'resolv'
    require 'timeout'

  #Temporary, require. These will be automatically passed in soon.
    require '/var/spool/cloud/meta-data.rb'
    os_info=`lsb_release -a`.downcase + `uname`.downcase
    ENV['RS_DISTRO']="ubuntu"

  #Escape the 4 problematic shell characters: ", $, `, and \ to get through the ssh command correctly
    def shell_escape(string)
      return string.gsub(/\\/, "\\\\\\").gsub(/\"/, "\\\"").gsub(/\$/, "\\\$").gsub(/\`/, "\\\\\`")
    end

  # Connect server machine to load balancer to start receiving traffic
    web_listener = node[:load_balancer][:web_listener_name]
    backend_name = node[:load_balancer][:backend_name]
    lb_host = node[:load_balancer][:website_dns]

  # Use cookies?
    sess_sticky = node[:load_balancer][:session_stickiness].downcase
    if sess_sticky && sess_sticky.match(/^(true|yes|on)$/)
      cookie_options = "-c #{ENV['EC2_INSTANCE_ID']}"
    end

  # How many conns do we tell the LB to bring to the AJP port?
    max_conn_per_svr = node[:load_balancer][:max_connections_per_lb] || 255

  # Connect the app to all running instances of the lb host
    addrs = Array.new
    lb_host.split.each do |item|
      addresses = Resolv.getaddresses(item)
      addresses.each do |address|
        addrs << address
      end
    end

    raise "Found  #{addrs.length} addresses for host #{lb_host}" if addrs.length == 0

    successful=0
    addrs.each do |addr|
      puts ">>>>>>>Attaching app to host #{addr} <<<<<<<<<<<<<<"

      # Using the default config file...no cookie persistence...and health checks
      sshcmd = "ssh -o StrictHostKeyChecking=no -o PasswordAuthentication=no root@#{addr}"
      cfg_cmd="/opt/rightscale/lb/bin/haproxy_config_server.rb"

      puts "ENV['EC2_LOCAL_IPV4'] = #{ENV['EC2_LOCAL_IPV4']}"
      puts "node[:ipaddress] = #{node[:ipaddress]}"
      target="#{ENV['EC2_LOCAL_IPV4']}:#{node[:load_balancer][:web_server_port]}"
      args= "-a add -w -l \"#{web_listener}\" -s \"#{backend_name}\" -t \"#{target}\" #{cookie_options} -e \" inter 3000 rise 2 fall 3 maxconn #{max_conn_per_svr}\" "
      args += " -k on " if node[:load_balancer][:health_check_uri] != nil && node[:load_balancer][:health_check_uri] != ""

      cmd = "#{sshcmd} #{cfg_cmd} #{shell_escape(args)}"
      puts cmd

      timeout=60*5 #@ 5min
      begin
        status = Timeout::timeout(timeout) do
          while true
            response = `#{cmd}`
            puts response #for debugging...
            break if response.include?("Haproxy restart sucessful")
            break if response.include?("Restart not required")
            puts "Retrying..."
            sleep 10
          end
        end
      rescue Timeout::Error => e
        puts "ERROR: Timeout after #{timeout/60} minutes."
        next
      end

      successful += 1

    end

    raise "Failure, only #{successful} out of #{addrs.length} lb hosts could be connected" if successful != addrs.length
  end
  not_if { node[:load_balancer][:website_dns].nil? }
end