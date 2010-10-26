require File.dirname(__FILE__) + "/../lib/helpmeout"
require 'spec'
require 'spec/autorun'
require 'active_support/all'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

Spec::Runner.configure do |config|

  config.before(:all) do
    @adapter = DataMapper.setup(:default, 'sqlite::memory:')
    DataMapper.finalize
    DataMapper.auto_migrate!
  end

  config.before(:each) do
    DataMapper::Repository.context << repository(:default)
  end

  config.after(:each) do
    DataMapper::Repository.context.pop
  end

end
