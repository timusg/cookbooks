package 'zip'
package 'unzip'

es_version = "0.20.6"
es_source = "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-#{es_version}.tar.gz"


ruby_block "reset group list" do
  action :nothing
  block do
    Etc.endgrent
  end
  notifies :run, "execute[set elasticsearch password]", :immediately
end


group "elasticsearch" do
  gid 1500
  group_name 'elasticsearch'
  not_if "grep elasticsearch /etc/group"
end

user "elasticsearch" do
  comment "elasticsearch server"
  username 'elasticsearch'
  uid 1500
  gid 1500
  home "/opt/elasticsearch"
  shell "/bin/bash"
  supports :manage_home => true
  notifies :create, resources(:ruby_block => "reset group list"), :immediately
  not_if "grep elasticsearch /etc/passwd"
end

execute "set elasticsearch password" do
  Chef::Log.info("Setting elasticsearch password")
  user 'root'
  command "echo elastic | passwd elasticsearch --stdin"
  action :nothing
end


remote_file "/tmp/elasticsearch-#{es_version}.tar.gz" do
  source es_source
  mode 00644
  notifies :run, "script[install-elasticsearch]", :immediately
  not_if do
    File.exists? "/tmp/elasticsearch-#{es_version}.tar.gz"
  end
end

script "install-elasticsearch" do
  Chef::Log.info("installing elasticsearch #{es_version} zip file...")
  user 'elasticsearch'
  interpreter "bash"
  cwd "/opt/elasticsearch"
  code <<-eoh
  rm -rf /opt/elasticsearch/*
  rm -rf /opt/elasticsearch*.zip
  tar -xvf /tmp/elasticsearch-#{es_version}.tar.gz
  rm -rf /opt/elasticsearch/elasticsearch
  ln -s /opt/elasticsearch/elasticsearch-#{es_version} /opt/elasticsearch/elasticsearch
  eoh
  notifies :run, "execute[change ownership to elasticsearch]"
  not_if do
    File.exists? "/opt/elasticsearch/elasticsearch-#{es_version}"
  end
end

execute "change ownership to elasticsearch" do
  user "root"
  cwd "/opt"
  Chef::Log.info("changing ownership for elasticsearch")
  command "chown -Rv 1500.1500 /opt/elasticsearch"
  action :nothing
end


directory "/etc/elasticsearch" do
  owner "root"
  group "root"
  mode 00755
  action :create
  not_if do
    File.exists? "/etc/elasticsearch"
  end
end

directory "/var/log/elasticsearch" do
  owner "elasticsearch"
  group "elasticsearch"
  mode 00755
  action :create
  not_if do
    File.exists? "/var/log/elasticsearch"
  end
end

template "/etc/init.d/elasticsearch" do
  source "elasticsearch.sh.erb"
  mode 00755
  owner 'root'
  notifies :restart, "service[elasticsearch]"
end

service "elasticsearch" do
  supports :status => true, :restart => true, :stop => true, :start => true
  action [ :enable, :start ]
end
