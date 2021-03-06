require 'yaml'
require 'erb'
require 'uri'

require "monorm/version"

require 'monorm/base'
require 'monorm/migrator'

MonoRM::PROJECT_ROOT_DIR = PROJECT_ROOT_DIR

module MonoRM

  def self.root
    PROJECT_ROOT_DIR
  end

  def self.config
    File.join root, 'config'
  end

  def self.db_config
    File.join config, 'database.yml'
  end

  def self.lib
    File.join root, 'lib'
  end

  def self.monorm
    File.join lib, 'monorm'
  end

  class MonoRM::DBInitializer
    def self.load_db_adapter

      adapter = URI.parse(ENV['DATABASE_URL']).scheme

      case adapter
      when 'postgres'
        adapter_path = File.join('monorm', 'db_adapters', 'pg_connection')
        require adapter_path
      when 'sqlite'
        adapter_path = File.join('monorm', 'db_adapters', 'sqlite_connection')
        require adapter_path
      else
        raise 'Database type not found!'
      end
    end
  end

  class MonoRM::MigrationInitializer
    def self.load_migrator
      migrator = URI.parse(ENV['DATABASE_URL']).scheme
      case migrator
      when 'postgres'
        migrator_path = File.join('monorm', 'db_migrators', 'pg_migration')
        require migrator_path
      when 'sqlite'
        migrator_path = File.join('monorm', 'db_migrators', 'sqlite_migration')
        require migrator_path
      else
        raise 'Database type not found!'
      end
    end
  end

end
