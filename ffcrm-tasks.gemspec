$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ffcrm-tasks/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'ffcrm-tasks'
  s.version     = FfcrmTasks::VERSION
  s.authors     = ['Tolga Yalcinkaya']
  s.email       = ['tolga@cloudarena.com']
  s.homepage    = 'http://www.cloudarena.com'
  s.summary     = "Advanced tasks for Fat Free CRM"
  s.description = "Commentable tasks and group visible tasks"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.13"
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "pg"
end
