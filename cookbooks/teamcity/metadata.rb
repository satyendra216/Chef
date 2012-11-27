maintainer 'Cloud Infrastructure'
maintainer_email 'csf@ultimatesoftware.com'
license 'our license'
description 'Configures TeamCity'
long_description ''
version '0.0.1'

depends 'rightscale'

recipe 'teamcity::configure', 'Configures TeamCity build agent properties file'
recipe 'teamcity::backup_volumes', 'Backups up TeamCity web server volumes'
recipe 'teamcity::setup_volumes', 'Sets up TeamCity web server volumes'

attribute 'core/aws_access_key_id',
  :display_name => 'aws access key id',
  :required => 'required',
  :recipes => ['teamcity::setup_volumes']

attribute 'core/aws_secret_access_key',
  :display_name => 'aws secret access key',
  :required => 'required',
  :recipes => ['teamcity::setup_volumes']

attribute 'deploy/admin_password_mongo',
  :display_name => 'administrator password for mongo',
  :required => 'required',
  :recipes => ['teamcity::configure']

attribute 'deploy/admin_user_mongo',
  :display_name => 'administrator user for mongo',
  :required => 'required',
  :recipes => ['teamcity::configure']

attribute 'teamcity/agent_name',
  :display_name => 'build agent name',
  :required => 'required',
  :recipes => ['teamcity::configure']

attribute 'teamcity/agent_type',
  :display_name => 'agent type',
  :required => 'required',
  :recipes => ['teamcity::configure']

attribute 'teamcity/instance_name',
  :display_name => 'instance name',
  :required => 'required',
  :recipes => ['teamcity::configure']

attribute 'teamcity/web_ip',
  :display_name => 'web ip',
  :required => 'optional',
  :default => '',
  :recipes => ['teamcity::configure']

attribute 'teamcity/web_server_ip',
  :display_name => 'teamcity server ip',
  :required => 'required',
  :recipes => ['teamcity::configure']
