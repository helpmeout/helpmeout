require 'dm-core'
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'sqlite://helpmeout.db')

require 'lib/models/failed_test'
require 'lib/models/failed_test_file'

DataMapper.finalize
DataMapper.auto_upgrade!

require 'helpmeout/formatter'
