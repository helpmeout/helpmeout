require 'dm-core'
require 'dm-migrations'
require 'rails/all'
DataMapper::Logger.new($stdout, :debug)
uri = "sqlite://#{File.expand_path('~')}/helpmeout.db"
puts uri
DataMapper.setup(:default, uri)

require 'helpmeout/failed_test'
require 'helpmeout/failed_test_file'

DataMapper.finalize
DataMapper.auto_upgrade!

require 'helpmeout/formatter'
