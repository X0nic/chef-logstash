default['logstash']['kibana']['repo'] = 'git://github.com/rashidkpc/Kibana.git'
default['logstash']['kibana']['sha'] = '806d9b4d7a88b102777cca8ec3cb472f3eb7b5b1'
default['logstash']['kibana']['basedir'] = "#{node['logstash']['basedir']}/kibana"
default['logstash']['kibana']['log_dir'] = '/var/log/kibana'
default['logstash']['kibana']['pid_dir'] = '/var/run/kibana'
default['logstash']['kibana']['home'] = "#{node['logstash']['kibana']['basedir']}/current"
default['logstash']['kibana']['server_name'] = node['ipaddress']
default['logstash']['kibana']['http_port'] = 80
default['logstash']['kibana']['auth']['enabled'] = false
default['logstash']['kibana']['auth']['user'] = 'admin'
default['logstash']['kibana']['auth']['password'] = 'unauthorized'

#Smart_index_pattern = 'logstash-%Y.%m.%d'
default['logstash']['kibana']['smart_index_pattern'] = 'logstash-%Y.%m.%d'

