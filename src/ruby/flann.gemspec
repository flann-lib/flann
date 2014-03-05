lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

# require 'flann/version'

Gem::Specification.new do |gem|
  gem.name = "flann"
  gem.version = '0.0.1'
  gem.summary = "Ruby interface for FLANN, approximate nearest neighbors methods in C"
  gem.description = "Ruby interface for FLANN, approximate nearest neighbors methods in C"
  gem.homepage = 'http://www.cs.ubc.ca/research/flann/'
  gem.authors = ['John Woods']
  gem.email =  ['john.o.woods@gmail.com']
  gem.license = 'BSD 2-clause'
  #gem.post_install_message = <<-EOF
#EOF

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 2.0'

  gem.add_dependency 'rdoc'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'pry'
end

