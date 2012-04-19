maintainer       "Cloud Infrastructure"
maintainer_email "ugf_ci@ultimatesoftware.com"
license          "our license"
description      "Deploys the UGF software to the environment"
long_description ""
version          "0.0.1"

supports "ubuntu"

recipe "load_balancer::configure_load_balancer_forwarding", "Adds an entry vhost (frontend) that forwards requests to the next target"
recipe "load_balancer::deregister_appserver_with_haproxy", "Deregisters an app server with each load balancer"
recipe "load_balancer::register_appserver_with_haproxy", "Registers an app server with each load balancer"
recipe "load_balancer::register_webserver_with_haproxy", "Registers a web server with each load balancer"

attribute "load_balancer/app_listener_names",
  :display_name => "app listener names",
  :description => "specifies which HAProxy servers pool to use",
  :required => "optional",
  :default  => "api80,api81,api82",
  :recipes => ["load_balancer::register_appserver_with_haproxy", "load_balancer::deregister_appserver_with_haproxy"]

attribute "load_balancer/app_server_ports",
  :display_name => "app server ports",
  :required => "optional",
  :default  => "80,81,82",
  :recipes  => ["load_balancer::register_appserver_with_haproxy"]

attribute "load_balancer/backend_name",
  :display_name => "backend name",
  :description => "A unique name for each back end e.g. (RS_INSTANCE_UUID)",
  :required => "optional",
  :recipes  => [
    "load_balancer::register_appserver_with_haproxy",
    "load_balancer::register_webserver_with_haproxy",
    "load_balancer::deregister_appserver_with_haproxy"
  ]

attribute "load_balancer/forwarding_ports",
  :display_name => "forwarding ports",
  :description => "The list of ports to be forwarded by the load balancer (i.e. 80,81,82,443)",
  :required => "required",
  :recipes  => ["load_balancer::configure_load_balancer_forwarding"]

attribute "load_balancer/health_check_uri",
  :display_name => "health check uri",
  :description => "Page to report the heart beat so the lb knows whether the server is up or not",
  :required => "optional",
  :default  => "/HealthCheck.html",
  :recipes  => ["load_balancer::register_appserver_with_haproxy", "load_balancer::register_webserver_with_haproxy"]

attribute "load_balancer/maintenance_page",
  :display_name => "maintenance page",
  :description => "Optional path for a maintenance page, relative to document root (i.e., "".../current/public""). The file must exist in the subtree of the vhost, which will be served by the web server if it's present. If ignored, it will default to '/system/maintenance.html'.",
  :required => "optional",
  :default => "/system/maintenance.html",
  :recipes => ["load_balancer::configure_load_balancer_forwarding"]

attribute "load_balancer/max_connections_per_lb",
  :display_name => "max connection per load balancer",
  :description => "Maximum number of connections per server",
  :required => "optional",
  :default  => "255",
  :recipes  => ["load_balancer::register_appserver_with_haproxy", "load_balancer::register_webserver_with_haproxy"]

attribute "load_balancer/private_ssh_key",
  :display_name => "private ssh key",
  :description => "The ssh key used to connect to the load balancer",
  :required => "optional",
  :recipes  => ["load_balancer::register_appserver_with_haproxy", "load_balancer::deregister_appserver_with_haproxy"]

attribute "load_balancer/session_stickiness",
  :display_name => "session stickiness",
  :required => "optional",
  :default  => "false",
  :recipes  => ["load_balancer::register_appserver_with_haproxy", "load_balancer::register_webserver_with_haproxy"]

attribute "load_balancer/ssl_certificate",
  :display_name => "ssl certificate",
  :description => "The contents of the SSL Certificate which can be obtained from the 'mycert.crt' file.",
  :required => "required",
  :recipes => ["load_balancer::configure_load_balancer_forwarding"]

attribute "load_balancer/ssl_key",
  :display_name => "ssl key",
  :description => "The contents of the SSL key file (key.pem) that's required for secure (https) connections.",
  :required => "required",
  :recipes => ["load_balancer::configure_load_balancer_forwarding"]

attribute "load_balancer/web_listener_name",
  :display_name => "web listener name",
  :description => "specifies which HAProxy servers pool to use",
  :required => "optional",
  :default  => "www",
  :recipes => ["load_balancer::register_webserver_with_haproxy"]

attribute "load_balancer/web_server_port",
  :display_name => "web server port",
  :required => "optional",
  :default  => "80",
  :recipes  => ["load_balancer::register_webserver_with_haproxy"]

attribute "load_balancer/website_dns",
  :display_name => "website dns name",
  :description => "The fully qualified domain name that the server will accept traffic for. Ex: www.globalincite.com. Also, sets the directory for your application's web files (/home/webapps/APPLICATION/current/). If you have multiple applications, you can run the code checkout script multiple times, each with a different value for APPLICATION, so each application will be stored in a unique directory. This must be a valid directory name. Do not use symbols in the name.",
  :required => "optional",
  :recipes  => [
    "load_balancer::configure_load_balancer_forwarding",
    "load_balancer::register_appserver_with_haproxy",
    "load_balancer::register_webserver_with_haproxy",
    "load_balancer::deregister_appserver_with_haproxy"
  ]