module Helpmeout
  module Config

    private
    def self.config
      @config ||= self.defaults.merge YAML.load_file(File.join(Rails.root, 'helpmeout.yaml')).symbolize_keys!
    end

    def self.method_missing(name, *args, &block)
      config[name]
    end

    def self.defaults
      {
        :exclude_prefixes => [ENV['GEM_HOME']],
        :database_home => Rails.root
      }
    end
  end
end
