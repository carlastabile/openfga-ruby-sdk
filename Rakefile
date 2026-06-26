require 'bundler/gem_tasks'

# release-please already pushes the tag and commit, so skip bundler's git push
Rake::Task['release:source_control_push'].clear
task 'release:source_control_push' do; end

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError
  # no rspec available
end
