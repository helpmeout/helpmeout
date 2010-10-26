require 'spec_helper'
require 'helpmeout/db_helper'

describe "DBHelper" do

  it 'should set up the database' do
    Helpmeout::Config.stub(:project_root => '/projects/this')
    DataMapper.should_receive(:setup).with(:default, 'sqlite:///projects/this/helpmeout.db')
    DataMapper.should_receive(:finalize)
    DataMapper.should_receive(:auto_upgrade!)
    Helpmeout::DBHelper.setup
  end


end
