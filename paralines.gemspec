Gem::Specification.new do |s|
	s.name = 'paralines'
	s.summary = 'Nice output to console/file from concurrent threads.'
	s.version = '1.1.1'
	s.authors = ['Yura Babak']
	s.email = ['yura.des@gmail.com']
	s.homepage = 'https://github.com/Inversion-des/paralines'
	s.license = 'MIT'
	s.files = %w[lib/paralines.rb README.md LICENSE.txt]
	s.add_development_dependency 'rspec', '~> 3.5'
	s.required_ruby_version = '>= 2.1'
end
