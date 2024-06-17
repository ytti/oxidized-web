require 'minitest/autorun'
require 'rack/test'
require 'oxidized/web/webapp'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  describe 'Get /' do
    it 'should redirect to /nodes' do
      get '/'

      _(last_response.redirect?).must_equal true
      follow_redirect!
      _(last_request.path).must_equal '/nodes'
    end
  end
end
