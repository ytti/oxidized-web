require_relative '../spec_helper'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  # issue #414: a "+" (and other special characters) in a node name must be
  # URL-encoded in the ?node_full= links. Otherwise the "+" in the query string
  # is decoded to a space server-side and the versions page fails to load.
  it 'url-encodes node_full in the node-list versions link' do
    nodes = mock('Oxidized::Nodes')
    nodes.expects(:list).returns(
      [{ name: 'router1+(test123+)', full_name: 'default/router1+(test123+)',
         ip: '10.0.0.1', model: 'ios', group: 'default',
         status: 'success', time: 'time', mtime: 'mtime' }]
    )
    app.set(:nodes, nodes)

    get '/nodes'
    _(last_response.ok?).must_equal true
    _(last_response.body).must_include 'node_full=default%2Frouter1%2B%28test123%2B%29'
    _(last_response.body.include?('node_full=default/router1+(test123+)')).must_equal false
  end
end
