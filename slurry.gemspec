Gem::Specification.new do |gem|

  gem.name    = 'slurry'
  gem.version = '0.0.1'
  gem.date    = Date.today.to_s

  gem.summary     = "A tool that caches json for graphite"
  gem.description = "A tool that caches json for graphite"

  gem.author   = 'Zach Leslie'
  gem.email    = 'xaque208@gmail.com'
  gem.homepage = 'https://github.com/xaque208/slurry'

  # ensure the gem is built out of versioned files
   gem.files = Dir['Rakefile', '{bin,lib}/**/*', 'etc/*.sample', 'README*', 'LICENSE*'] & %x(git ls-files -z).split("\0")

   gem.executables << 'slurry'

   gem.add_dependency('json')

end

