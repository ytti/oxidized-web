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

  describe 'post /nodes/conf_search' do
    it 'returns 200 with empty results when search_in_conf_textbox is missing' do
      post '/nodes/conf_search'
      _(last_response.ok?).must_equal true
    end

    it 'returns 200 with empty results when search_in_conf_textbox is blank' do
      post '/nodes/conf_search', search_in_conf_textbox: ''
      _(last_response.ok?).must_equal true
    end

    it 'returns 200 with empty results when regex is malformed (no crash)' do
      post '/nodes/conf_search', search_in_conf_textbox: '['
      _(last_response.ok?).must_equal true
    end

    it 'returns 200 with matches when regex is valid' do
      @nodes.expects(:list).returns(
        [{ name: 'sw5', full_name: 'sw5', group: nil }]
      )
      @nodes.expects(:fetch).with('sw5', nil).returns("hostname sw5\n")
      post '/nodes/conf_search', search_in_conf_textbox: 'hostname'
      _(last_response.ok?).must_equal true
    end
  end
end
