require_relative 'spec_helper'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  describe '/' do
    it 'should redirect to /nodes' do
      get '/'

      _(last_response.redirect?).must_equal true
      follow_redirect!
      _(last_request.path).must_equal '/nodes'
    end
  end
end
