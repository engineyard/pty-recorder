Gem::Specification.new do |s|
  s.name = "pty-recorder"
  s.version = "0.0.1"
  s.summary = "Record input and output of commands run in a fully interactive PTY"
  s.description = s.summary
  s.has_rdoc = false
  s.extra_rdoc_files = ["README.md", "LICENSE"]
  s.authors = ["Martin Emde"]
  s.email = "cloud-engineering@engineyard.com"
  s.homepage = "http://github.com/engineyard/pty-recorder"

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~>2.0'

  s.require_path = 'lib'
  s.files = Dir['{lib}/**/*']
end
