require 'dm-core'
require 'dm-constraints'
module Helpmeout
  class FailedTest
    include DataMapper::Resource

    property :id, Serial
    property :exception_message, String #leftover?
    property :exception_classname, String
    property :backtrace, String
    property :example_description, String

    has n, :failed_test_files, :constraint => :destroy!
  end
end
