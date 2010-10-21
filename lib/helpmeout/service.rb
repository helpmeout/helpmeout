require 'rest_client'
require 'builder'
require 'active_support/all'

module Helpmeout
  class Service
    
    def add_fix(failed_test)
      RestClient.post 'http://localhost:3000/fixes', generate_fix_xml(failed_test), :content_type => :xml
    end

    def query_fix(backtrace, exception_classname)
      response = RestClient.get('http://localhost:3000/fixes', :params => {:backtrace => clean_backtrace(backtrace).join("\n"), :exception_classname => exception_classname})
      Hash.from_xml response
    end

    private 
    def generate_fix_xml(failed_test)
      xml = Builder::XmlMarkup.new( :indent => 2 )
      xml.instruct!
      xml.fix do |f|
        f.exception_message failed_test.exception_message
        f.backtrace clean_backtrace(failed_test.backtrace)
        if failed_test.failed_test_files.any? 
          f.fix_files_attributes do |ffa|
            ffa.path "" # hack to always get an array of fixed_files. 
            ffa.content_before ""
            ffa.content_after ""
          end
          failed_test.failed_test_files.each do |failed_test_file|
            f.fix_files_attributes do |ffa|
              ffa.path failed_test_file.path
              ffa.content_before failed_test_file.content
              ffa.content_after File.read(failed_test_file.path)
            end
          end
        end
      end
      xml.target!
    end

    def clean_backtrace(backtrace)
      backtrace.collect do |line|
        Config.exclude_prefixes.each do |prefix|
          line = line.gsub prefix, "EXCLUDE"
        end

        unless line.starts_with?(Rails.root)
          line
        end
      end.compact
    end

  end
end
