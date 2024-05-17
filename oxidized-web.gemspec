Gem::Specification.new do |s|
  s.name              = 'oxidized-web'
  s.version           = '0.13.1'
  s.licenses          = %w[Apache-2.0]
  s.platform          = Gem::Platform::RUBY
  s.authors           = ['Saku Ytti', 'Samer Abdel-Hafez']
  s.email             = %w[saku@ytti.fi sam@arahant.net]
  s.homepage          = 'http://github.com/ytti/oxidized-web'
  s.summary           = 'sinatra API + webUI for oxidized'
  s.description       = 'puma+sinatra+haml webUI + REST API for oxidized'
  s.files             = %x(git ls-files -z).split("\x0")
  s.executables       = %w[]
  s.require_path      = 'lib'

  s.metadata['rubygems_mfa_required'] = 'true'

  s.required_ruby_version =                       '>= 2.7'

  s.add_runtime_dependency 'charlock_holmes',     '~> 0.7.5'
  s.add_runtime_dependency 'emk-sinatra-url-for', '~> 0.2'
  s.add_runtime_dependency 'haml',                '~> 5.0'
  s.add_runtime_dependency 'htmlentities',        '~> 4.3'
  s.add_runtime_dependency 'oxidized',            '~> 0.26'
  s.add_runtime_dependency 'puma',                '~> 3.11.4'
  s.add_runtime_dependency 'sass',                '~> 3.3'
  s.add_runtime_dependency 'sinatra',             '~> 1.4', '>= 1.4.6'
  s.add_runtime_dependency 'sinatra-contrib',     '~> 1.4', '>= 1.4.6'
  s.add_runtime_dependency 'json',                '~> 2.3'
  s.add_runtime_dependency 'rack-test',           '~> 0.7.0'

  s.add_development_dependency 'bundler',              '~> 2.2'
  s.add_development_dependency 'rails_best_practices', '~> 1.19'
  s.add_development_dependency 'rake',                 '~> 13.0'
  s.add_development_dependency 'rubocop',              '~> 1.63.5'
  s.add_development_dependency 'rubocop-minitest',     '~> 0.34.5'
  s.add_development_dependency 'rubocop-rake',         '~> 0.6.0'
  s.add_development_dependency 'rubocop-rails',        '~> 2.25.0'
  s.add_development_dependency 'simplecov',            '~> 0.22.0'
  s.add_development_dependency 'simplecov-cobertura',  '~> 2.1.0'
  s.add_development_dependency 'simplecov-html',       '~> 0.12.3'
end
