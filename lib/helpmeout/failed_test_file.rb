require 'dm-core'
module Helpmeout
  class FailedTestFile
    include DataMapper::Resource

    property :id, Serial
    property :path, String
    property :content, String

    belongs_to :failed_test
  end
end
