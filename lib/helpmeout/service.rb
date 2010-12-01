require 'rubygems'
require 'rest_client'
require 'builder'
require 'active_support/all'

module Helpmeout
  class Service
    
    def add_fix(failed_test)
      RestClient.post 'http://blooming-frost-23.heroku.com/fixes', generate_fix_xml(failed_test), :content_type => :xml unless failed_test.failed_test_files.empty?
    end

    def query_fix(backtrace, exception_classname, exception_message)
      response = RestClient.post('http://blooming-frost-23.heroku.com/fixes/find', :params => {:backtrace => clean_backtrace(backtrace).join("\n"), :exception_classname => exception_classname, :code_line => code_line_from_backtrace(backtrace), :exception_message => exception_message})
      Hash.from_xml response
    end

    private 
    def generate_fix_xml(failed_test)
      xml = Builder::XmlMarkup.new( :indent => 2 )
      xml.instruct!
      xml.fix do |f|
        f.exception_message failed_test.exception_message
        f.exception_classname failed_test.exception_classname
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
      expanded_backtrace = expand_backtrace(backtrace)
      expanded_backtrace.collect do |line|
        Config.exclude_prefixes.each do |prefix|
          line = line.gsub prefix, "EXCLUDE"
        end

        unless line.starts_with?(Config::project_root)
          line
        end
      end.compact
    end

    def expand_backtrace(backtrace)
      backtrace.collect do |line|
        segments = line.split(':')
        segments[0] = File.expand_path(segments[0])
        segments.join(':')
      end
    end

    def code_line_from_backtrace(backtrace)
      expanded_backtrace = expand_backtrace(backtrace)
      first_project_line = expanded_backtrace.detect do |line|
        !Config.exclude_prefixes.any? {|prefix| line.starts_with?(prefix)} && line.starts_with?(Config.project_root)
      end
      if first_project_line
        (filename, line) = first_project_line.split(':')
        file = File.open(filename)
        file.readlines[line.to_i - 1]
      else
        nil
      end
    end

  end
end
