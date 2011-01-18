# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "kakuro_solver/version"

Gem::Specification.new do |s|
  s.name        = "kakuro_solver"
  s.version     = Kakuro::Solver::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Shlomi Fish']
  s.email       = ["shlomif@iglu.org.il"]
  s.homepage    = "http://www.shlomifish.org/open-source/projects/japanese-puzzle-games/kakuro/"
  s.summary     = "A Solver for Kakuro / Cross-sums"
  s.description = "A Solver for Kakuro / Cross-sums"

  s.rubyforge_project = "kakuro_solver"

  s.files         = `cat Manifest`.split("\n")
  s.test_files    = `cat Manifest`.split("\n").select { |x| x =~ /^t\// }
  # s.executables   = `cat Manifest`.split("\n").select { |x| x =~ /^bin\// }
  s.require_paths = ["lib"]
  
  # s.add_dependency "text-format", "1.0.0"
  # s.add_dependency "highline", "~> 1.5.1"
  # s.add_dependency "json", "~> 1.4.6"
  # s.add_dependency "launchy", "~> 0.3.7"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~>2.0.0"
  s.add_development_dependency "bundler"
end
