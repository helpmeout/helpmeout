require 'rubygems'
# begin
#   Bundler.setup(:default, :development)
# rescue Bundler::BundlerError => e
#   $stderr.puts e.message
#   $stderr.puts "Run `bundle install` to install missing gems"
#   exit e.status_code
# end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "helpmeout"
  gem.summary = %Q{Collect and suggest bugfixes}
  gem.description = %Q{Yet to be determined}
  gem.email = "manuel.kallenbach@gmail.com"
  gem.homepage = "http://github.com/manukall/helpmeout"
  gem.authors = ["Manuel Kallenbach"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  spec.add_runtime_dependency 'jabber4r', '> 0.1'
  #  spec.add_development_dependency 'rspec', '> 1.2.3'
  gem.add_development_dependency "bundler", "~> 1.0.0"
  gem.add_development_dependency "jeweler", "~> 1.4.0"
  gem.add_development_dependency "rcov", ">= 0"
  gem.add_dependency "dm-core"
  gem.add_dependency "dm-sqlite-adapter"
  gem.add_dependency "dm-migrations"
  gem.add_dependency "dm-constraints"
  gem.add_dependency "rest-client"
  gem.add_dependency "builder"
  gem.add_dependency "differ"
  gem.add_dependency "rest-client"
end

require 'spec'
require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end


task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "helpmeout #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
