namespace :db do
  desc 'Run migrations'
  task :migrate, [:version] do |t, args|
    require 'sequel/core'
    require 'yaml'

    environment = ENV['RACK_ENV'] || 'local'
    config_file = File.expand_path("./config/#{environment}.yml")
    raise StandardError, "No config file was found at #{config_file}" unless File.exist?(config_file)

    config = YAML.safe_load(File.open(config_file), [Symbol])
    Sequel.extension :migration
    version = args[:version].to_i if args[:version]

    db = Sequel.connect(config[:database])
    Sequel::Migrator.run(db, './migrations', target: version)
  end
end
