Gem::Specification.new do |s|
  s.name              = 'oxidized-web'
  s.version           = '0.9.1'
  s.licenses          = %w( Apache-2.0 )
  s.platform          = Gem::Platform::RUBY
  s.authors           = ['Saku Ytti', 'Samer Abdel-Hafez']
  s.email             = %w(saku@ytti.fi sam@arahant.net)
  s.homepage          = 'http://github.com/ytti/oxidized-web'
  s.summary           = 'sinatra API + webUI for oxidized'
  s.description       = 'puma+sinatra+haml webUI + REST API for oxidized'
  s.rubyforge_project = s.name
  s.files             = `git ls-files`.split("\n")
  s.executables       = %w( )
  s.require_path      = 'lib'

  s.required_ruby_version =                       '>= 1.9.3'
  s.add_runtime_dependency 'oxidized',            '~> 0.19'
  s.add_runtime_dependency 'puma',                '~> 3'
  s.add_runtime_dependency 'sinatra',             '~> 1.4', '>= 1.4.6'
  s.add_runtime_dependency 'sinatra-contrib',     '~> 1.4', '>= 1.4.6'
  s.add_runtime_dependency 'haml',                '~> 4.0'
  s.add_runtime_dependency 'sass',                '~> 3.3'
  s.add_runtime_dependency 'emk-sinatra-url-for', '~> 0.2'
  s.add_runtime_dependency 'htmlentities',        '~> 4.3'
end
