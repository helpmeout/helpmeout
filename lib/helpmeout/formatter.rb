require 'rspec/core/formatters/base_text_formatter'
require 'sqlite3'

module Helpmeout
  class Formatter < RSpec::Core::Formatters::BaseTextFormatter
    
    def start(example_count)
      set_up_database
    end

    def example_started(example)
    end

    def example_failed(example)
      exception = example.execution_result[:exception_encountered]
      backtrace = exception.backtrace.join("\n")

      db.transaction 
      delete_failed_test(example.full_description)
      create_failed_test exception.message, backtrace, example.full_description
      inserted_test_id = db.last_insert_row_id

      project_files = get_project_files(exception.backtrace)
      project_files.each do |file_path|
        create_failed_test_file(file_path, inserted_test_id)
      end
      db.commit
    end

    def example_passed(example)
    end


    private

    def db
      @db ||= SQLite3::Database.new( "helpmeout.db" )
    end

    def set_up_database
      db.execute("create table if not exists failed_tests(id INTEGER PRIMARY KEY, exception_message VARCHAR, backtrace VARCHAR, example_description VARCHAR)")
      db.execute("create table if not exists failed_test_files(id INTEGER PRIMARY KEY, path VARCHAR, content VARCHAR, failed_test_id INTEGER)")
    end

    def get_project_files(backtrace)
      backtrace.collect{ |line| line.starts_with?(Rails.root) ? line.split(':')[0] : nil}.compact.uniq
    end

    def delete_failed_test(description)
      failed_test_id = db.execute("SELECT id FROM failed_tests WHERE example_description = ?", description).first
      if failed_test_id
        db.execute "DELETE FROM failed_tests WHERE id = ?", failed_test_id
        db.execute "DELETE FROM failed_test_files WHERE failed_test_id = ?", failed_test_id
      end
    end

    def create_failed_test_file(path, failed_test_id)
      file_content = File.read(path)
      db.execute("INSERT INTO failed_test_files VALUES(?, ?, ?, ?)",
                 nil, path, file_content, failed_test_id )
    end

    def create_failed_test(exception_message, backtrace, example_description)
      db.execute("INSERT INTO failed_tests VALUES(?, ?, ?, ?)",
                 nil, exception_message, backtrace, example_description)
    end

  end
end
