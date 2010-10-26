module Helpmeout
  class DBHelper
    def self.setup
      project_root = Config.project_root
      DataMapper.setup(:default, 'sqlite://' + File.join (project_root, '/helpmeout.db'))
      DataMapper.finalize
      DataMapper.auto_upgrade!
    end
  end
end
