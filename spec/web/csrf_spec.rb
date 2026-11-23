require_relative '../spec_helper'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  before do
    @nodes = mock('Oxidized::Nodes')
    app.set(:nodes, @nodes)
  end

  describe 'CSRF protection' do
    it 'includes authenticity_token in the conf_search form on every page' do
      @nodes.stubs(:list).returns([])

      get '/nodes'

      _(last_response.ok?).must_equal true
      _(last_response.body).must_include("name='authenticity_token'")
    end

    it 'includes authenticity_token in the version diffs form' do
      versions = [{ oid: 'C006', time: Time.parse('2025-02-05 19:49:00 +0100') }]
      diff = { patch: "- old line\n+ new line\n", stat: [1, 1] }
      @nodes.stubs(:version).returns(versions)
      @nodes.stubs(:get_diff).returns(diff)

      get '/node/version/diffs?node=sw5&group=&oid=C006&epoch=0&num=1'

      _(last_response.ok?).must_equal true
      _(last_response.body).must_include("name='authenticity_token'")
    end

    it 'sets a SameSite=Strict session cookie' do
      @nodes.stubs(:list).returns([])

      get '/nodes'

      _(last_response.ok?).must_equal true
      cookie = last_response.headers['Set-Cookie'].to_s
      _(cookie.downcase).must_include('samesite=strict')
    end
  end
end
