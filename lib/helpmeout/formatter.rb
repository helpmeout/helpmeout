require 'dm-core'
require 'dm-migrations'
require 'spec/runner/formatter/base_formatter'
require 'helpmeout/failed_test'
require 'helpmeout/failed_test_file'
require 'differ'
require 'erb'
require 'launchy'

  module Helpmeout
    
    PATH_TO_ERB = "#{File.dirname(__FILE__)}/formatter/helpmeout.html.erb"
    PATH_TO_EXAMPLE_ERB = "#{File.dirname(__FILE__)}/formatter/failed_example.html.erb"
    
    class Formatter < Spec::Runner::Formatter::BaseFormatter
      include ERB::Util

      def initialize(options, output)
        if String === output
          FileUtils.mkdir_p(File.dirname(output))
          @output = File.open(output, 'w')
        else
          @output = output
        end
        @body = ''
        DBHelper.setup
      end
      
      def example_failed(example, counter, failure)
        exception = failure.exception
        backtrace = exception.backtrace.join("\n")

        delete_failed_test(example)
        inserted_test = create_failed_test exception.message, exception.class.name, backtrace, example.description

        project_files = get_project_files(exception.backtrace)
        project_files.each do |file_path|
          create_failed_test_file(file_path, inserted_test.id)
        end

        @description = example.description
        @message = exception.message
        @fixes = service.query_fix(exception.backtrace, exception.class.name)

        template = ERB.new(File.new(PATH_TO_EXAMPLE_ERB).read)
        @body << template.result(binding)
    end

    def example_passed(example)
      if failed_test = matching_failed_test(example)
        service.add_fix(failed_test)
        failed_test.destroy!
      end
    end

    def dump_summary(duration, example_count, failure_count, pending_count)
      template = ERB.new(File.new(PATH_TO_ERB).read)
      output.puts(template.result(binding))
      output.flush
      if File === @output
        Launchy::Browser.run(File.expand_path(@output.path))
      end
    end

    private

    def delete_failed_test(example)
      failed_test = matching_failed_test(example)
      if failed_test
        failed_test.destroy
      end
    end

    def create_failed_test_file(path, failed_test_id)
      file_content = File.read(path)
      FailedTestFile.create( :path => path, :content => file_content,
                            :failed_test_id => failed_test_id)
    end

    def create_failed_test(exception_message, exception_classname, backtrace, example_description)
      FailedTest.create(:exception_message => exception_message,
                        :exception_classname => exception_classname,
                        :backtrace => backtrace,
                        :example_description => example_description
                       )
    end

    def matching_failed_test(example)
      FailedTest.first(:example_description => example.description)
    end

    def get_project_files(backtrace)
      backtrace.collect do |line| 
        filename = line.split(':')[0]
        File.expand_path(filename).starts_with?(Config.project_root) ? filename : nil 
      end.uniq.compact
    end

    def service
      @service ||= Service.new
    end

    def output
      @output
    end

  end
end
