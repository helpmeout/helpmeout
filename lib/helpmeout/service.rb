require 'rest_client'

module Helpmeout
  class Service
    
    def add_fix(failed_test)
      data = {
        :exception_message => failed_test.exception_message,
        :backtrace => failed_test.backtrace,
        :fix_file_attributes => failed_test.failed_test_files.collect do |failed_test_file|
          { :path => failed_test_file.path,
            :content_before => failed_test_file.content,
            :content_after => File.read(failed_test_file.path)
          }
        end
      }

      RestClient.post 'http://localhost:3000/fixes', data.to_xml
      debugger
      data.each do |key, value|
        puts "=" * 40
        puts key
        puts "=" * 40
        puts value
      end
    end

  end
end
