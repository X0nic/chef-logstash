include_recipe "git"
include_recipe "logrotate"

kibana_base = node['logstash']['kibana']['basedir']
kibana_home = node['logstash']['kibana']['home']
kibana_log_dir = node['logstash']['kibana']['log_dir']
kibana_pid_dir = node['logstash']['kibana']['pid_dir']

if Chef::Config[:solo]
  es_server_ip = node['logstash']['elasticsearch_ip'].empty? ? '127.0.0.1' : node['logstash']['elasticsearch_ip']
else
  es_server_results = search(:node, "roles:#{node['logstash']['elasticsearch_role']} AND chef_environment:#{node.chef_environment}")
  unless es_server_results.empty?
    es_server_ip = es_server_results[0]['ipaddress']
  else
    es_server_ip = node['logstash']['elasticsearch_ip'].empty? ? '127.0.0.1' : node['logstash']['elasticsearch_ip']
  end
end

es_server_port = node['logstash']['elasticsearch_port'].empty? ? '9200' : node['logstash']['elasticsearch_port']


user "kibana" do
  supports :manage_home => true
  home "/home/kibana"
  shell "/bin/bash"
end

[ kibana_pid_dir, kibana_log_dir ].each do |dir|
  Chef::Log.debug(dir)
  directory dir do
    owner 'kibana'
    group 'kibana'
    recursive true
  end
end

Chef::Log.debug(kibana_base)
directory kibana_base do
  owner 'kibana'
  group 'kibana'
  recursive true
end

# for some annoying reason Gemfile.lock is shipped w/ kibana
file "gemfile_lock" do
  path  "#{node['logstash']['kibana']['basedir']}/#{node['logstash']['kibana']['sha']}/Gemfile.lock"
  action :delete
end

git "#{node['logstash']['kibana']['basedir']}/#{node['logstash']['kibana']['sha']}" do
  repository node['logstash']['kibana']['repo']
  branch "kibana-ruby"
  action :sync
  user 'kibana'
  group 'kibana'
  notifies :delete, "file[gemfile_lock]", :immediately
end

link kibana_home do
  to "#{node['logstash']['kibana']['basedir']}/#{node['logstash']['kibana']['sha']}"
end

template '/home/kibana/.bash_profile' do # let bash handle our env vars
  source 'kibana-bash_profile.erb'
  owner 'kibana'
  group 'kibana'
  variables(
            :pid_dir => kibana_pid_dir,
            :log_dir => kibana_log_dir,
            :app_name => "kibana",
            :kibana_port => node['logstash']['kibana']['http_port'],
            :smart_index => node['logstash']['kibana']['smart_index_pattern'],
            :es_ip => es_server_ip,
            :es_port => es_server_port,
            :server_name => node['logstash']['kibana']['server_name']
            )
end

template "/etc/init.d/kibana" do
  source "kibana.init.erb"
  owner 'root'
  mode "755"
  variables(
            :kibana_home => kibana_home,
            :user => 'kibana'
            )
end

template "#{kibana_home}/KibanaConfig.rb" do
  source "kibana-config.rb.erb"
  owner 'kibana'
  mode 0755
end

template "#{kibana_home}/kibana-daemon.rb" do
  source "kibana-daemon.rb.erb"
  owner 'kibana'
  mode 0755
end

bash "bundle install" do
  cwd kibana_home
  code "bundle install"
  not_if { ::File.exists? "#{kibana_home}/Gemfile.lock" }
end


service "kibana" do
  supports :status => true, :restart => true
  action [:enable, :start]
  subscribes :restart, [ "link[#{kibana_home}]", "template[#{kibana_home}/KibanaConfig.rb]", "template[#{kibana_home}/kibana-daemon.rb]" ]
end

logrotate_app "kibana" do
  cookbook "logrotate"
  path "/var/log/kibana/kibana.output"
  frequency "daily"
  options [ "missingok", "notifempty" ]
  rotate 30
  create "644 kibana kibana"
end

