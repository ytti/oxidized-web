lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oxidized/web/version'

Gem::Specification.new do |s|
  s.name              = 'oxidized-web'
  s.version           = Oxidized::API::WEB_VERSION
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

  s.required_ruby_version =                       '>= 3.1'

  s.add_runtime_dependency 'charlock_holmes',     '~> 0.7.5'
  s.add_runtime_dependency 'emk-sinatra-url-for', '~> 0.2'
  s.add_runtime_dependency 'haml',                '~> 6.0'
  s.add_runtime_dependency 'htmlentities',        '~> 4.3'
  s.add_runtime_dependency 'json',                '~> 2.3'
  s.add_runtime_dependency 'oxidized',            '~> 0.26'
  s.add_runtime_dependency 'puma',                '>= 3.11.4', '< 6.5.0'
  s.add_runtime_dependency 'sinatra',             '>= 1.4.6', '< 5.0'
  s.add_runtime_dependency 'sinatra-contrib',     '>= 1.4.6', '< 5.0'

  s.add_development_dependency 'bundler',              '~> 2.2'
  s.add_development_dependency 'minitest',             '~> 5.18'
  s.add_development_dependency 'mocha',                '~> 2.1'
  s.add_development_dependency 'rack-test',            '~> 2.1'
  s.add_development_dependency 'rails_best_practices', '~> 1.19'
  s.add_development_dependency 'rake',                 '~> 13.0'
  s.add_development_dependency 'rubocop',              '~> 1.71.0'
  s.add_development_dependency 'rubocop-minitest',     '~> 0.35.0'
  s.add_development_dependency 'rubocop-rails',        '~> 2.25.0'
  s.add_development_dependency 'rubocop-rake',         '~> 0.6.0'
  s.add_development_dependency 'simplecov',            '~> 0.22.0'
  s.add_development_dependency 'simplecov-cobertura',  '~> 2.1.0'
  s.add_development_dependency 'simplecov-html',       '~> 0.13.1'
end
