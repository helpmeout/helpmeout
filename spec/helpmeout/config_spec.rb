require 'spec_helper'
require 'helpmeout/config'

describe "Config" do

  before(:each) do
    @project_path = '/path/to/project'
    Rails.stub(:root).and_return(@project_path)
  end

  describe 'config' do
    it 'should load the file helpmeout.yaml in the rails root and apply the defaults' do
      config_stub = {:exclude_prefixes => '/exclude/prefix'}
      Helpmeout::Config.stub(:defaults => {:exclude_prefixes => '/somewhere/else', :database_home => '/database/home'})
      YAML.should_receive(:load_file).with('/path/to/project/helpmeout.yaml').and_return(config_stub)
      expected = {:exclude_prefixes => '/exclude/prefix', :database_home => '/database/home'}
      Helpmeout::Config.send(:config).should == expected
      Helpmeout::Config.instance_variable_get("@config").should == expected
    end
  end

  describe 'method_missing' do
    it 'should return the hashs value for the given key' do
      @config = {:exclude_path => '/path/to/exclude'}
      Helpmeout::Config.stub(:config => @config)
      Helpmeout::Config.exclude_path.should == '/path/to/exclude'
    end

    it 'returns nil if the hash has no such value' do
      @config = {:exclude_path => '/path/to/exclude'}
      Helpmeout::Config.stub(:config => @config)
      Helpmeout::Config.include_path.should be_nil
    end

  end

end
