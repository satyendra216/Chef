ruby_scripts_dir = node["ruby_scripts"]["dir"]

puts "ruby scripts dir: #{ruby_scripts_dir}"

template "#{ruby_scripts_dir}/provision.rb" do
  source 'scripts/provision.erb'
  variables(
    :db_server => node[:deploy][:db_server],
    :sarmus_port => node[:deploy][:sarmus_port]
  )
end

powershell "Provisioning data" do
  source("ruby #{ruby_scripts_dir}/provision.rb")
end

remote_recipe 'Reindexing elastic search' do
  recipe 'deploy::reindex_elastic_search'
  recipients_tags ['server:type=db']
end