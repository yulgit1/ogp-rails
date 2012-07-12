desc "Run Continuous Integration Suite (tests, coverage, docs)"
task :ci do
  
  require 'jettywrapper'
  jetty_params = Jettywrapper.load_config.merge({
    :jetty_home => File.expand_path(File.dirname(__FILE__) + '/../../jetty'),
    :jetty_port => 8983,
    :startup_wait => 25
  })

  error = nil
  error = Jettywrapper.wrap(jetty_params) do
    Rails.env = "test"
    Rake::Task["doc"].invoke
    Rake::Task["simplecov"].invoke
  end
  raise "TEST FAILURES: #{error}" if error
  
end
