require 'spec_helper'
require 'helpmeout/formatter'
require 'rails'

describe "Formatter" do
  before(:each) do
    @output = StringIO.new
    @formatter = Helpmeout::Formatter.new(@output)
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
      failed_test = stub("Failed Test")
      @formatter.should_receive(:matching_failed_test).with(:example).and_return(failed_test)
      failed_test.should_receive(:destroy)
      @formatter.send(:delete_failed_test, :example)
    end
  end

  describe "create_failed_test_file" do
    it "should create a failed test file row" do
      File.should_receive(:read).with("/home/user/project/file.rb").
        and_return(:content_of_the_file)
      Helpmeout::FailedTestFile.should_receive(:create).with({
        :path => "/home/user/project/file.rb",
        :content => :content_of_the_file, :failed_test_id => 37
      })
      @formatter.send(:create_failed_test_file, "/home/user/project/file.rb", 37)
    end
  end

  describe "create_failed_test" do
    it "should create a failed test" do
      Helpmeout::FailedTest.should_receive(:create).with(:exception_message => :message,
                                              :backtrace => :backtrace,
                                              :example_description => :description)
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
                       :full_description => 'description'
                     )
    end

    it "should call delete_failed_test" do
      @formatter.should_receive(:delete_failed_test).with(@example)
      @formatter.example_failed(@example)
    end

    it "should create a failed test" do
      @formatter.should_receive(:create_failed_test).with(
        :exception_message, "file1:12\nfile2:23", 'description')
        @formatter.example_failed(@example)
    end

    it "should create failed_test_files for the project files" do
      failed_test_stub = stub(:id => 37)
      @formatter.stub(:create_failed_test).and_return(failed_test_stub)
      @formatter.should_receive(:get_project_files).
        with(["file1:12", "file2:23"]).and_return(["file1", "file2"])
      @formatter.should_receive(:create_failed_test_file).with("file1", 37) 
      @formatter.should_receive(:create_failed_test_file).with("file2", 37) 
      @formatter.example_failed(@example)
    end
  end
  

  describe "example_passed" do
    before(:each) do
      @service = stub("Service").as_null_object
      @formatter.stub(:service => @service)
    end

    it "should do nothing if the example did not fail before" do
      example = stub('Example').as_null_object
      @formatter.should_receive(:matching_failed_test).with(example).and_return(nil)
      @formatter.should_not_receive(:service)
      @formatter.example_passed(example)
    end

    it "should call service.add_fix if the example failed before" do
      example = stub('Example').as_null_object
      @formatter.should_receive(:matching_failed_test).with(example).and_return(:failed_test)
      @service.should_receive(:add_fix).with(:failed_test)
      @formatter.example_passed(example)
    end
  end

end
