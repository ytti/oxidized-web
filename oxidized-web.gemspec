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

  s.required_ruby_version = '>= 3.1'

  # Gemspec strategy
  #
  # For dependency and optional dependencies, we try to set the minimal
  # dependency lower than the Ubuntu Noble or Debian Bookworm package version,
  # so that native packages can be used.
  # We limit the maximal version so that dependabot can warn about new versions
  # and we can test them before activating them in Oxidized.
  #
  # development dependencies are set to the latest minor version of a library
  # and updated after having tested them

  s.add_dependency 'charlock_holmes',     '>= 0.7.5', '< 0.8.0'
  s.add_dependency 'emk-sinatra-url-for', '~> 0.2'
  # haml 7.0 requires ruby >= 3.2, so keep it < 7
  s.add_dependency 'haml',                '>= 6.0.0', '< 7.0.0'
  s.add_dependency 'htmlentities',        '>= 4.3.0', '< 4.5.0'
  s.add_dependency 'json',                '>= 2.3.0', '< 2.19.0'
  # Only depend on a minimal version of Oxidized so we don't need to
  # update the gemspec for new Oxidized releases
  s.add_dependency 'oxidized',            '>= 0.34.1'
  s.add_dependency 'puma',                '>= 6.6', '< 7.2'
  s.add_dependency 'sinatra',             '>= 4.1.1', '< 4.3.0'
  s.add_dependency 'sinatra-contrib',     '>= 4.1.1', '< 4.3.0'

  s.add_development_dependency 'minitest',             '~> 5.18'
  s.add_development_dependency 'mocha',                '~> 2.1'
  s.add_development_dependency 'rack-test',            '~> 2.1'
  s.add_development_dependency 'rails_best_practices', '~> 1.19'
  s.add_development_dependency 'rake',                 '~> 13.0'
  s.add_development_dependency 'rubocop',              '~> 1.81.1'
  s.add_development_dependency 'rubocop-minitest',     '~> 0.38.0'
  s.add_development_dependency 'rubocop-rails',        '~> 2.34.2'
  s.add_development_dependency 'rubocop-rake',         '~> 0.7.1'
  s.add_development_dependency 'simplecov',            '~> 0.22.0'
  s.add_development_dependency 'simplecov-html',       '~> 0.13.1'
end
