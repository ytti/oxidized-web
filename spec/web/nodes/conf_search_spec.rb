require_relative '../../spec_helper'
require 'json'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  before do
    @nodes = mock('Oxidized::Nodes')
    app.set(:nodes, @nodes)
  end

  describe 'POST /nodes/conf_search' do
    it 'returns 400 for an invalid regular expression' do
      post '/nodes/conf_search', search_in_conf_textbox: '[invalid('

      _(last_response.status).must_equal 400
      _(last_response.body).must_include 'Invalid regular expression'
    end

    it 'returns an empty list when no configs match' do
      @nodes.expects(:list).returns([{ name: 'sw1', full_name: 'Switch 1' }])
      @nodes.expects(:fetch).with('sw1', nil).returns('hostname sw1')

      post '/nodes/conf_search.json', search_in_conf_textbox: 'interface'

      _(last_response.ok?).must_equal true
      _(JSON.parse(last_response.body)).must_equal []
    end

    it 'returns nodes whose configs match the pattern' do
      @nodes.expects(:list).returns(
        [{ name: 'sw1', full_name: 'Switch 1' },
         { name: 'sw2', full_name: 'Switch 2' }]
      )
      @nodes.expects(:fetch).with('sw1', nil).returns("hostname sw1\ninterface GigabitEthernet0/0")
      @nodes.expects(:fetch).with('sw2', nil).returns('hostname sw2')

      post '/nodes/conf_search.json', search_in_conf_textbox: 'interface'

      _(last_response.ok?).must_equal true
      result = JSON.parse(last_response.body)
      _(result.length).must_equal 1
      _(result.first['node']).must_equal 'sw1'
    end

    it 'skips nodes that exceed the search timeout and still returns 200' do
      @nodes.expects(:list).returns([{ name: 'sw1', full_name: 'Switch 1' }])
      @nodes.expects(:fetch).with('sw1', nil).returns('hostname sw1')
      Timeout.stubs(:timeout).raises(Timeout::Error)

      post '/nodes/conf_search.json', search_in_conf_textbox: 'hostname'

      _(last_response.ok?).must_equal true
      _(JSON.parse(last_response.body)).must_equal []
    end
  end
end
