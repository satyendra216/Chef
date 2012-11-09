rightscale_marker :begin

raise "Ubuntu not supported" if node[:platform] == "ubuntu"

include_recipe 'core::download_vendor_artifacts_prereqs'

template "#{node[:ruby_scripts_dir]}/download_rsyslog.rb" do
  local true
  source "#{node[:ruby_scripts_dir]}/download_vendor_artifacts.erb"
  variables(
    :aws_access_key_id => node[:core][:aws_access_key_id],
    :aws_secret_access_key => node[:core][:aws_secret_access_key],
    :s3_bucket => node[:core][:s3_bucket],
    :s3_repository => 'Vendor',
    :product => 'rsyslog',
    :version => '1.1.120',
    :artifacts => 'rsyslogwa.exe',
    :target_directory => '/installs',
    :unzip => false
  )
  not_if { File.exist?('/installs/rsyslogwa.exe') }
end

powershell 'Download rsyslog' do
  source("ruby #{node[:ruby_scripts_dir]}/download_rsyslog.rb")
  not_if { File.exist?('/installs/rsyslogwa.exe') }
end

agent_dir = "#{ENV['ProgramFiles(x86)']}\\RSyslog\\Agent"

powershell 'Install rsyslog' do
  source('c:\\installs\\rsyslogwa.exe -i /S /v /qn')
  not_if { File.exist?(agent_dir) }
end

template "#{agent_dir}\\settings.xml" do
  source 'settings.erb'
  variables(:remote_log_server => node[:rsyslog][:remote_log_server])
end

powershell 'Import settings' do
  parameters( { 'AGENT_DIR' => agent_dir } )
  script = <<'EOF'
    cd "$env:AGENT_DIR"
    RSyslogConfigClient.exe "settings.xml" /f
EOF
  source( script )
  not_if { File.exist?(agent_dir) }
end

service 'rsyslogcl.exe' do
  action :start
end

rightscale_marker :end

