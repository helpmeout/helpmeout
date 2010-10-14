require 'spec_helper'
require 'helpmeout/formatter'
require 'rails'

describe "Formatter" do
  before(:each) do
    @output = StringIO.new
    @formatter = Helpmeout::Formatter.new(@output)
    @db = stub("database").as_null_object
    @formatter.stub(:db => @db)
  end

  describe "start" do
    it "should initialize the database setup" do
      @formatter.should_receive(:set_up_database)
      @formatter.start(12)
    end
  end

  describe "set_up_database" do

    it "should create the failed_tests table" do
      @db.should_receive(:execute).with("create table if not exists failed_tests(id INTEGER PRIMARY KEY, exception_message VARCHAR, backtrace VARCHAR, example_description VARCHAR)")
      @formatter.send(:set_up_database)
    end

    it "should create the failed_test_files table" do
      @db.should_receive(:execute).with("create table if not exists failed_test_files(id INTEGER PRIMARY KEY, path VARCHAR, content VARCHAR, failed_test_id INTEGER)")
      @formatter.send(:set_up_database)
    end
  end

  describe "get_project_files" do
    it "should return the files in the backtrace that are in the projects directory" do
      Rails.stub(:root).and_return("/home/user/rails/project")
      backtrace = [ 
        "/home/user/rails/project/spec/models/story_spec.rb:34",
        "/home/user/.rvm/rubies/whatever.rb:54",
        "/usr/lib/somelib:42",
        "/home/user/rails/project/app/models/story.rb:12"
      ]
      @formatter.send(:get_project_files, backtrace).should ==
        [
        "/home/user/rails/project/spec/models/story_spec.rb",
        "/home/user/rails/project/app/models/story.rb"
      ]
    end
  end

  describe "delete_failed_test" do
    it "should do nothing if no test exists with that example description" do
      @formatter.should_receive(:matching_failed_test).with(:example).and_return(nil)
      @formatter.send(:delete_failed_test, :example)
    end

    it "should delete the failed test and its files" do
      @formatter.should_receive(:matching_failed_test).with(:example).and_return({:id => "37"})
      @db.should_receive(:execute).with("DELETE FROM failed_tests WHERE id = ?", "37")
      @db.should_receive(:execute).with("DELETE FROM failed_test_files WHERE failed_test_id = ?", "37")
      @formatter.send(:delete_failed_test, :example)
    end
  end

  describe "db" do
    it "should create and cache the database connection" do
      @formatter.unstub(:db)
      SQLite3::Database.should_receive(:new).with("helpmeout.db").once.and_return(:db_connection)
      @formatter.send(:db).should == :db_connection
      @formatter.send(:db).should == :db_connection #execute again to see if the connection is cached
    end
  end

  describe "create_failed_test_file" do
    it "should create a failed test file row" do
      File.should_receive(:read).with("/home/user/project/file.rb").
        and_return(:content_of_the_file)
      @db.should_receive(:execute).with("INSERT INTO failed_test_files VALUES(?, ?, ?, ?)",
                                        nil, "/home/user/project/file.rb", :content_of_the_file, 37)
      @formatter.send(:create_failed_test_file, "/home/user/project/file.rb", 37)
    end
  end

  describe "create_failed_test" do
    it "should create a failed test" do
      @db.should_receive(:execute).with("INSERT INTO failed_tests VALUES(?, ?, ?, ?)",
                                        nil, :message, :backtrace, :description)
      @formatter.send(:create_failed_test, :message, :backtrace, :description)
    end
  end

  describe "example_failed" do
    before(:each) do
      @exception = stub("Exception", 
                        :message => :exception_message,
                        :backtrace => ["file1:12", "file2:23"]
                       )

      @example = stub("Example",
                       :execution_result => 
                            {:exception_encountered => @exception},
                       :full_description => :description
                     )
    end

    it "should call delete_failed_test" do
      @formatter.should_receive(:delete_failed_test).with(@example)
      @formatter.example_failed(@example)
    end

    it "should create a failed test" do
      @formatter.should_receive(:create_failed_test).with(
        :exception_message, "file1:12\nfile2:23", :description)
        @formatter.example_failed(@example)
    end

    it "should create failed_test_files for the project files" do
      @db.stub(:last_insert_row_id => 37)
      @formatter.should_receive(:get_project_files).
        with(["file1:12", "file2:23"]).and_return(["file1", "file2"])
     @formatter.should_receive(:create_failed_test_file).with("file1", 37) 
     @formatter.should_receive(:create_failed_test_file).with("file2", 37) 
     @formatter.example_failed(@example)
    end
  end
  
  describe "rows_as_hashes" do
    before(:each) do
      @db_rows = [ 
        ["id", "name", "zip_code"],
        ["12", "palim", "12321"],
        ["23", "schmuh", "323232"]
      ]
    end
    it "should return the rows for the query as hashes" do
      @db.should_receive("execute2").with("SELECT * FROM something").and_return(@db_rows)
      @formatter.send(:rows_as_hashes, "SELECT * FROM something").should ==
        [
          { :id => "12", :name => "palim", :zip_code => "12321"}.with_indifferent_access,
          { :id => "23", :name => "schmuh", :zip_code => "323232"}.with_indifferent_access
      ]
    end

    it "should return an empty array if there are no results" do
      @db.should_receive("execute2").with("SELECT * FROM something").and_return([])
      @formatter.send(:rows_as_hashes, "SELECT * FROM something").should == []
    end
  end

  describe "example_passed" do
    before(:each) do
      @service = stub("Service").as_null_object
      @formatter.stub(:service => @service)
    end

    it "should do nothing if the example did not fail before" do
      @formatter.should_receive(:matching_failed_test).with(:example).and_return(nil)
      @formatter.should_not_receive(:service)
      @formatter.example_passed(:example)
    end

    it "should call service.add_fix if the example failed before" do
      @formatter.should_receive(:matching_failed_test).with(:example).and_return(:failed_test)
      @service.should_receive(:add_fix).with(:failed_test)
      @formatter.example_passed(:example)
    end
  end

end
