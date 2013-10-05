# desc "Explaining what the task does"
# task :ffcrm-tasks do
#   # Task goes here
# end


namespace :ffcrm do
  desc "ffcrm-task's rspec test"
  task :rspec do
    spec = File.expand_path('../../../spec', __FILE__)
    command = "rspec -Ispec:lib #{spec}"
    puts command if verbose
    system(command)
  end
end
