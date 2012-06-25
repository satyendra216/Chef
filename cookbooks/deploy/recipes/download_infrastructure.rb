ruby_scripts_dir = node['ruby_scripts_dir']
Dir.mkdir(ruby_scripts_dir) unless File.exist? ruby_scripts_dir

template "#{ruby_scripts_dir}/download_infrastructure.rb" do
  source 'scripts/download_artifacts.erb'
  variables(
    :aws_access_key_id => node[:deploy][:aws_access_key_id],
    :aws_secret_access_key => node[:deploy][:aws_secret_access_key],
    :artifacts => node[:deploy][:infrastructure_artifacts],
    :target_directory => node[:infrastructure_directory],
    :revision => node[:deploy][:infrastructure_revision],
    :s3_bucket => node[:deploy][:s3_bucket],
    :s3_repository => node[:deploy][:s3_api_repository],
    :s3_directory => 'Services'
  )
end

if node[:platform] == "ubuntu"
  bash 'Downloading artifacts' do
    code <<-EOF
      ruby #{ruby_scripts_dir}/download_infrastructure.rb
    EOF
  end
else
  powershell "Downloading artifacts" do
    source("ruby #{ruby_scripts_dir}/download_infrastructure.rb")
  end
end