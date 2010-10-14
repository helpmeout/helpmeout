require 'dm-core'
require 'dm-migrations'
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'sqlite://helpmeout.db')

require 'helpmeout/failed_test'
require 'helpmeout/failed_test_file'

DataMapper.finalize
DataMapper.auto_upgrade!

require 'helpmeout/formatter'
