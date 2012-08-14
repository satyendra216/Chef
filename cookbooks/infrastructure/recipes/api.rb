bash 'Set document root and configure Passenger' do
  code <<-EOF
    if grep -q DocumentRoot /etc/apache2/apache2.conf; then
        echo "document root already set"
        exit 0
    fi

    echo LoadModule passenger_module /opt/passenger-3.0.12/ext/apache2/mod_passenger.so >> /etc/apache2/apache2.conf
    echo PassengerRoot /opt/passenger-3.0.12 >> /etc/apache2/apache2.conf
    echo PassengerRuby /opt/ruby/active/bin/ruby >> /etc/apache2/apache2.conf
    echo PassengerDefaultUser root >> /etc/apache2/apache2.conf

    echo DocumentRoot "/var/www/api/public" >> /etc/apache2/apache2.conf
  EOF
end

template '/etc/apache2/conf.d/status.conf' do
  source 'status_conf.erb'
end

template "/var/www/HealthCheck.html" do
  mode "0644"
  source 'health_check.erb'
end

bash 'Setup website' do
  code <<-EOF
    mkdir --parents /var/www/api
    cp -r #{node['infrastructure_directory']}/InfrastructureServices/* /var/www/api

    echo "" >> /var/www/api/log/production.log
    echo "" >> /var/www/api/log/rest.log
    chmod --recursive 0666 /var/www/api/log
    chown --recursive www-data:www-data /var/www/api/log

    cp /var/www/HealthCheck.html /var/www/api/doc

    cd /var/www/api

    bundle install

    service apache2 restart

    curl http://localhost/deployments.json
  EOF
end

ruby_block 'Setup syslog-ng config file' do
  block do
    File.open('/etc/syslog-ng/syslog-ng.conf', 'a') do |file|
      file.puts('source s_production { file("/var/www/api/log/production.log"); };')
      file.puts('filter f_production { not program("logger"); };')
      file.puts('destination d_production { program("logger -s -p local0.notice -t [production] \$MSG\n" flush_lines(1)); };')
      file.puts('log { source(s_production); destination(d_production); };')

      file.puts('source s_rest { file("/var/www/api/log/rest.log"); };')
      file.puts('filter f_rest { not program("logger"); };')
      file.puts('destination d_rest { program("logger -s -p local1.notice -t [rest] \$MSG\n" flush_lines(1)); };')
      file.puts('log { source(s_rest); destination(d_rest); };')
    end
  end
  not_if { File.read('/etc/syslog-ng/syslog-ng.conf').include?('/var/www/api/log/production.log') }
end

bash 'Restart syslog-ng and setup refresh schedule' do
  code <<-EOF
    service syslog-ng restart

    if ! grep syslog-ng /etc/crontab; then
      echo '# reload syslog-ng for local logger destinations.' >> /etc/crontab
      echo '*/2 * * * * root logger -p local0.notice "$(service syslog-ng reload 2>&1)"' >> /etc/crontab
      echo '*/2 * * * * root logger -p local1.notice "$(service syslog-ng reload 2>&1)"' >> /etc/crontab
    fi
  EOF
end



