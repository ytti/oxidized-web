# Needed to get the error output on the console and not in last_response.body
ENV['APP_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'oxidized'
require 'oxidized/web/webapp'
require 'mocha/minitest'
