# Install the Mule_ESB

version = node[:deploy][:mule_version]

# apt-get detects if debian package is already installed - no need to replicate its functionality
# NOTE maven2 installs java runtime
# may need to remove sun java6
bash 'install mule prerequisites' do
    code <<-EOF
    export DEBIAN_FRONTEND=noninteractive
    apt-get -yqq install openjdk-6-jre
    java -version
    mkdir -p ~/.m2
    apt-get -yqq install maven2
    mvn --version
    apt-get -yqq install tomcat6
  EOF
end

local_filename = '/etc/bash.bashrc'
f = File.open(local_filename, 'r+'); contents = f.read; f.close
append_contents = <<-'EOF'
export LANG=en_US.UTF-8
export MULE_HOME=/opt/mule
export JAVA_HOME=/usr/lib/jvm/java-6-openjdk/jre
export MAVEN_HOME=/usr/share/maven2
export MAVEN_OPTS='-Xmx512m -XX:MaxPermSize=256m'
export PATH=$PATH:$MULE_HOME/bin:$JAVA_HOME/bin
EOF

special_chars =  %r{
    ([\[$@\\\]])
    }x

append_contents.split(/\n/).each do |entry|
        check_entry =  entry.gsub(special_chars){'\\' + $1}
        puts "probing #{check_entry}" if $DEBUG
        if contents !~ Regexp.new(check_entry)
                puts "need to append #{entry}"  if $DEBUG
                contents += entry + "\n"
        end
end

File.open(local_filename, 'r+') {|f| f.puts contents}

log 'bash profile updated.'

# NOTE: mule is 180MB
if !File.exists?('/opt/mule/bin')
  bash 'install mule' do
    code <<-EOF
    mkdir -p ~/Installs
    cd ~/Installs
    # initial version - upload 200 MB from the web
    wget -q http://s3.amazonaws.com/MuleEE/mule-ee-distribution-standalone-mmc-#{version}.tar.gz
    tar xf mule-ee-distribution-standalone-mmc-#{version}.tar.gz
    mkdir -p /opt/mule
    pushd /opt/mule
    cp -R ~/Installs/mule-enterprise-standalone-#{version}/* .
    chmod -R 777 .
  EOF
end
  log 'Mule service is installed'
else
  log 'Mule already installed.'
end

# source bash.bashrc does not seem to work yet.
# may need to run the resolvelink.sh
# script to trouble shoot multiple java and log4j

log "Checking project [/root/.m2/org/mule/mule/#{version}/mule-#{version}.pom]."

if !File.exists?("/root/.m2/org/mule/mule/#{version}/mule-#{version}.pom")

  bash 'run maven in quiet mode' do
    code <<-EOF
    cd /opt/mule/bin
    sed -i 's/-B/-B -q/' populate_m2_repo.groovy
    EOF
  end

  bash 'populate maven repositories' do
    code <<-EOF
    cd /opt/mule/bin
    export LANG=en_US.UTF-8
    export MULE_HOME=/opt/mule
    export JAVA_HOME=/usr/lib/jvm/java-6-openjdk/jre
    export MAVEN_HOME=/usr/share/maven2
    export MAVEN_OPTS='-Xmx512m -XX:MaxPermSize=256m'
    export PATH=$PATH:$MULE_HOME/bin:$JAVA_HOME/bin
    if [ -x populate_m2_repo ] ; then
      ./populate_m2_repo ~/.m2
    fi
    LOG_FILE=/tmp/populate_m2_repo.log.$$
    echo 'running with redirection to the temporary log file'
    if [ -x populate_m2_repo ] ; then
      ./populate_m2_repo ~/.m2 > $LOG_FILE 2>&1
    fi
    if [ -f $LOG_FILE ] ; then
      /usr/bin/tail -10 $LOG_FILE
    else
      echo "no log file, ignoring"
    fi
    # temporarily suppress the exit status, need to debug
    exit 0
    EOF
  end
  log 'maven repositories successfully populated.'
else
  log 'maven repositories already populated.'
end
