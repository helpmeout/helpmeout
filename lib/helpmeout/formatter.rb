require 'rspec/core/formatters/base_text_formatter'
require 'helpmeout/failed_test'
require 'helpmeout/failed_test_file'

module Helpmeout
  class Formatter < RSpec::Core::Formatters::BaseTextFormatter
    
    def example_failed(example)
      exception = example.execution_result[:exception_encountered]
      backtrace = exception.backtrace.join("\n")

      delete_failed_test(example)
      inserted_test = create_failed_test exception.message, backtrace, example.full_description

      project_files = get_project_files(exception.backtrace)
      project_files.each do |file_path|
        create_failed_test_file(file_path, inserted_test.id)
      end
      puts "=" * 40
      puts "FAILED: " + example.full_description
    end

    def example_passed(example)
      if failed_test = matching_failed_test(example)
        service.add_fix(failed_test)
      end
      puts "=" * 40
      puts "PASSED: " + example.full_description
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

    def create_failed_test(exception_message, backtrace, example_description)
      FailedTest.create(:exception_message => exception_message,
                        :backtrace => backtrace,
                        :example_description => example_description
                       )
    end

    def matching_failed_test(example)
      FailedTest.first(:example_description => example.full_description)
    end

    def get_project_files(backtrace)
      backtrace.collect {|line| line.starts_with?(Rails.root) ? line.split(':')[0] : nil }.uniq.compact
    end

    def service
      @service ||= Service.new
    end

  end
end
