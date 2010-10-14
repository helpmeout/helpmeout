module HelpmeOut
  class FailedTest
    include DataMapper::Resource

    property :id, Serial
    property :exception_message, String
    property :backtrace, String
    property :example_description, String

    has_n :failed_test_files
  end
end
