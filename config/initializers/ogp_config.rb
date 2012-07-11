# OpenGeoportal specific configuration
solr_yaml = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), '..', 'environments', 'solr.yml')))[Rails.env]
proxy_yaml = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), '..', 'environments', 'proxy.yml')))[Rails.env]
ogp_yaml = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), '..', 'environments',  'ogp.yml')))


OgpRails::Application.config.solr_url = solr_yaml['serviceProxyAddress'] || solr_yaml['serviceAddress']
OgpRails::Application.config.ogpConfig = {
  :config => ogp_yaml.merge({ 
    :search => solr_yaml
  })
}

OgpRails::Application.config.ogpConfig[:config]['institutions']['Stanford']['proxy'] = proxy_yaml 
