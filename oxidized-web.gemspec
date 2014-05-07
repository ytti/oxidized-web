Gem::Specification.new do |s|
  s.name              = 'oxidized-web'
  s.version           = '0.0.3'
  s.platform          = Gem::Platform::RUBY
  s.authors           = [ 'Saku Ytti' ]
  s.email             = %w( saku@ytti.fi )
  s.homepage          = 'http://github.com/ytti/oxidized-web'
  s.summary           = 'sinatra API + webUI for oxidized'
  s.description       = 'puma+sinatra+haml webUI + REST API for oxidized'
  s.rubyforge_project = s.name
  s.files             = `git ls-files`.split("\n")
  s.executables       = %w( )
  s.require_path      = 'lib'

  s.add_dependency 'oxidized', '>= 0.0.57'
  s.add_dependency 'puma'
  s.add_dependency 'sinatra'
  s.add_dependency 'sinatra-contrib'
  s.add_dependency 'haml'
  s.add_dependency 'sass'
end
