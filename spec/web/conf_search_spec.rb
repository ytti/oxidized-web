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

    describe 'with non-ASCII characters' do
      # Output modules (e.g. git/rugged) return the config as ASCII-8BIT
      before do
        @nodes.expects(:list).returns(
          [{ name: 'utf8', full_name: 'utf8', group: nil },
           { name: 'latin1', full_name: 'latin1', group: nil },
           { name: 'ascii', full_name: 'ascii', group: nil }]
        )
        @nodes.expects(:fetch).with('utf8', nil)
              .returns("hostname utf8\ndescription Bod\xC3\xB8 \xC3\xA5\n".b)
        @nodes.expects(:fetch).with('latin1', nil)
              .returns("hostname latin1\ndescription Bod\xF8 \xE5\n".b)
        @nodes.expects(:fetch).with('ascii', nil)
              .returns("hostname ascii\ndescription Bodo a\n".b)
      end

      it 'finds UTF-8 and Latin1 encoded configs' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'Bodø å'
        _(last_response.ok?).must_equal true
        _(JSON.parse(last_response.body)).must_equal [
          { 'node' => 'utf8', 'full_name' => 'utf8' },
          { 'node' => 'latin1', 'full_name' => 'latin1' }
        ]
      end

      it 'still finds ASCII search terms in all configs' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'description'
        _(last_response.ok?).must_equal true
        _(JSON.parse(last_response.body)).must_equal [
          { 'node' => 'utf8', 'full_name' => 'utf8' },
          { 'node' => 'latin1', 'full_name' => 'latin1' },
          { 'node' => 'ascii', 'full_name' => 'ascii' }
        ]
      end
    end
  end
end
