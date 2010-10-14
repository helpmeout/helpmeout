module Helpmeout
  class FailedTest
    include DataMapper::Resource

    property :id, Serial
    property :exception_message, String
    property :backtrace, String
    property :example_description, String

    has n, :failed_test_files, :dependent => :destroy
  end
end
