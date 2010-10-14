require 'rest_client'
require 'builder'

module Helpmeout
  class Service
    
    def add_fix(failed_test)
      xml = Builder::XmlMarkup.new( :indent => 2 )
      xml.instruct!
      xml.fix do |f|
        f.exception_message failed_test.exception_message
        f.backtrace failed_test.backtrace
          f.fix_files_attributes do |ffa|
          failed_test.failed_test_files.each do |failed_test_file|
            ffa.path failed_test_file.path
            ffa.content_before failed_test_file.content
            ffa.content_after File.read(failed_test_file.path)
          end
        end
      end

      puts xml
      # data = {
      #   :exception_message => failed_test.exception_message,
      #   :backtrace => failed_test.backtrace,
      #   :fix_file_attributes => failed_test.failed_test_files.collect do |failed_test_file|
      #     { :path => failed_test_file.path,
      #       :content_before => failed_test_file.content,
      #       :content_after => File.read(failed_test_file.path)
      #     }
      #   end
      # }

      RestClient.post 'http://localhost:3000/fixes', xml, :content_type => :xml
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
