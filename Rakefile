require 'bundler/gem_tasks'

# release-please already pushes the tag and commit, so skip bundler's git push
task 'release:source_control_push' do
  # no-op
end

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError
  # no rspec available
end
