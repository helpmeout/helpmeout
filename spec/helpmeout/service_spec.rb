require 'spec_helper'
require 'helpmeout/formatter'
require 'rails'

describe "Service" do
  before(:each) do
    @service = Helpmeout::Service.new
    @failed_test = Helpmeout::FailedTest.new( 
                    :exception_message => 'Something very bad happened',
                    :backtrace => 
                    "/home/user/file.rb\n/home/user/other_file.rb\n/lib/rails/whatever.rb"
                                 )
  end

  describe "generate_fix_xml" do
    it "should generate xml that Rails understands if there are no fix_files" do
      @service.send(:generate_fix_xml, @failed_test).should == File.read("#{File.dirname(__FILE__)}/fix_no_files.xml")
    end
  end

  describe "generate_fix_xml" do
    it "should generate xml that Rails understands if there is one fix_files" do
      expected_xml = File.read("#{File.dirname(__FILE__)}/fix_one_file.xml")
      @failed_test_file = Helpmeout::FailedTestFile.new(:path => 'path/file.rb', :content => "Broken\nFile\nContent")
      File.should_receive(:read).with('path/file.rb').and_return("Fixed\nFile\nContent")
      @failed_test.stub(:failed_test_files => [@failed_test_file])
      @service.send(:generate_fix_xml, @failed_test).should == expected_xml
    end
  end

end
