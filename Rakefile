require 'rake'

task :default => 'gembuild'

desc "build the gem"
task :gembuild do
  %x(gem build ./gemspec)
end