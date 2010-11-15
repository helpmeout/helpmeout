require 'spec_helper'
require 'helpmeout/formatter'
require 'rails'

describe "Service" do
  before(:each) do
    Helpmeout::Config.stub(:exclude_prefixes => ['/lib/rails'])
    @service = Helpmeout::Service.new
    @failed_test = Helpmeout::FailedTest.new( 
                    :exception_message => 'Something very bad happened',
                    :exception_classname => 'ExceptionClass',
                    :backtrace => 
                    "/home/user/file.rb\n/home/user/other_file.rb\n/lib/rails/whatever.rb"
                                 )
  end

  describe "generate_fix_xml" do
    it "should generate xml that Rails understands if there are no fix_files" do
      @service.send(:generate_fix_xml, @failed_test).should == File.read("#{File.dirname(__FILE__)}/fix_no_files.xml")
    end

    it "should generate xml that Rails understands if there is one fix_files" do
      expected_xml = File.read("#{File.dirname(__FILE__)}/fix_one_file.xml")
      @failed_test_file = Helpmeout::FailedTestFile.new(:path => 'path/file.rb', :content => "Broken\nFile\nContent")
      File.should_receive(:read).with('path/file.rb').and_return("Fixed\nFile\nContent")
      @failed_test.stub(:failed_test_files => [@failed_test_file])
      @service.send(:generate_fix_xml, @failed_test).should == expected_xml
    end
  end

  describe "query_fix" do
    it 'should query the server for fixes with a cleaned backtrace and the exception class and the code line' do
      backtrace = "/home/user/ruby/whatever.rb:48\n%\n%\n/home/user/ruby/palim.rb:300"
      @service.should_receive(:clean_backtrace).with(backtrace).and_return(['cleaned','backtrace'])
      @service.should_receive(:code_line_from_backtrace).with(backtrace).and_return('code line')
      Hash.should_receive(:from_xml).with(:response).and_return(:fixes_hash)
      RestClient.should_receive(:get).with('http://localhost:3000/fixes', :params => {:backtrace => "cleaned\nbacktrace", :exception_classname => :exception_classname, :code_line => 'code line'}).and_return(:response)
      @service.query_fix(backtrace, :exception_classname).should == :fixes_hash
    end
  end


  describe 'clean_backtrace' do
    it 'removes files in the project directory from the backtrace' do
      Helpmeout::Config.stub(:exclude_prefixes => [])
      Helpmeout::Config.stub(:project_root => '/projects/this')
      backtrace = ['/projects/this/fail.rb', '/lib/something/else.rb']
      @service.should_receive(:expand_backtrace).with(:backtrace).and_return(backtrace)
      @service.send(:clean_backtrace, :backtrace).should == ['/lib/something/else.rb']
    end

    it 'replaces the exclude prefixes with EXCLUDE' do
      Helpmeout::Config.stub(:exclude_prefixes => [ '/lib/something',
                                                    '/projects/this/vendor' ])
      backtrace = [ '/lib/something/ruby.rb', 
                    '/project/this/palim.rb', 
                    '/projects/this/vendor/plugin.rb' ]

      @service.should_receive(:expand_backtrace).with(:backtrace).and_return(backtrace)
      @service.send(:clean_backtrace, :backtrace).should == [  'EXCLUDE/ruby.rb',
                                                              '/project/this/palim.rb',
                                                              'EXCLUDE/plugin.rb' ]
    end

    it 'keeps files with exclude_prefix even if they are in the project path' do
      Helpmeout::Config.stub(:project_root).and_return('/home/projects')
      Helpmeout::Config.stub(:exclude_prefixes => '/home/projects/vendor')
      backtrace = [ '/home/projects/remove.rb',
                    '/home/projects/vendor/keep.rb' ]
      @service.should_receive(:expand_backtrace).with(:backtrace).and_return(backtrace)
      @service.send(:clean_backtrace, :backtrace).should == [ 'EXCLUDE/keep.rb' ]
    end

  end

  describe 'expand_backtrace' do
    it 'expands relative paths in the backtrace' do
      backtrace = [ '/lib/ruby/file.rb:13', './spec/file.rb:12' ]
      File.should_receive(:expand_path).with('/lib/ruby/file.rb').and_return('/lib/ruby/file.rb')
      File.should_receive(:expand_path).with('./spec/file.rb').and_return('/projects/this/spec/file.rb')
      @service.send(:expand_backtrace, backtrace).should == ['/lib/ruby/file.rb:13', '/projects/this/spec/file.rb:12' ]
    end
  end

  describe 'code_line_from_backtrace' do
    it 'return the line of the first project file in the backtrace' do
      Helpmeout::Config.stub(:project_root).and_return('/home/projects')
      Helpmeout::Config.stub(:exclude_prefixes => '/home/projects/vendor')
      backtrace = "/home/projects/vendor/rails/some.rb:13\n/lib/ruby.rb:12\n/home/projects/models/post.rb:2"
      file_stub = stub(:readlines => ['Line 1', 'Line 2'])
      @service.stub(:expand_backtrace).and_return(backtrace)
      File.should_receive(:open).with('/home/projects/models/post.rb').and_return(file_stub)
      @service.send(:code_line_from_backtrace, backtrace).should == 'Line 2'
    end
  end

end
