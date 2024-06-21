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
      _(last_response.location).must_equal 'http://example.org/nodes'
    end
  end
end
