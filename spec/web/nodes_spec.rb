require_relative '../spec_helper'
require 'json'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  before do
    @nodes = mock('Oxidized::Nodes')
    @nodes.expects(:list).returns(
      [{ name: 'sw4', ip: '10.10.10.10', model: 'ios', time: 'time', mtime: 'mtime' },
       { name: 'sw5', ip: '10.10.10.5',  model: 'ios', time: 'time', mtime: 'mtime' },
       { name: 'sw6', ip: '10.10.10.6',  model: 'ios', time: 'time', mtime: 'mtime' },
       { name: 'sw7', ip: '10.10.10.7',  model: 'ios', time: 'time', mtime: 'mtime', group: 'group1' },
       { name: 'sw8', ip: '10.10.10.8',  model: 'aos', time: 'time', mtime: 'mtime', group: 'group1' },
       { name: 'sw9', ip: '10.10.10.9',  model: 'aos', time: 'time', mtime: 'mtime', group: 'gr/oup1' }]
    )
    app.set(:nodes, @nodes)
  end

  describe '/nodes.?:format?' do
    it 'shows all nodes' do
      get '/nodes.json'

      _(last_response.ok?).must_equal true
      result = JSON.parse(last_response.body)
      _(result.length).must_equal 6
    end
  end

  describe '/nodes/conf_search.?:format?' do
    before do
      config = [
        'interface ge-0/0/0',
        '  description uplink to core',
        '  mtu 9000',
        'interface ge-0/0/1',
        '  description access port',
        'system {',
        '  host-name sw4',
        '}'
      ].join("\n")
      @nodes.stubs(:fetch).returns('no match here')
      @nodes.stubs(:fetch).with('sw4', nil).returns(config)
    end

    it 'lists only nodes whose configuration matches' do
      post '/nodes/conf_search.json', search_in_conf_textbox: 'description'

      _(last_response.ok?).must_equal true
      result = JSON.parse(last_response.body)
      _(result.length).must_equal 1
      _(result[0]['node']).must_equal 'sw4'
    end

    it 'returns a snippet with two lines of context around each match' do
      post '/nodes/conf_search.json', search_in_conf_textbox: 'description'

      matches = JSON.parse(last_response.body)[0]['matches']
      _(matches.length).must_equal 2

      first = matches[0]
      _(first['line_number']).must_equal 2
      _(first['snippet'].map { |l| l['number'] }).must_equal [1, 2, 3, 4]
      _(first['snippet'][1]['match']).must_equal true
      _(first['snippet'][1]['text']).must_equal '  description uplink to core'
      _(first['snippet'][0]['match']).must_equal false

      second = matches[1]
      _(second['line_number']).must_equal 5
      _(second['snippet'].map { |l| l['number'] }).must_equal [3, 4, 5, 6, 7]
    end

    it 'highlights the matched text in the html view' do
      post '/nodes/conf_search', search_in_conf_textbox: 'description'

      _(last_response.ok?).must_equal true
      _(last_response.body).must_include '<mark>description</mark>'
    end

    it 'treats the search term as a regular expression by default' do
      post '/nodes/conf_search.json', search_in_conf_textbox: 'ge-0/0/.'

      result = JSON.parse(last_response.body)
      _(result.length).must_equal 1
      _(result[0]['matches'].map { |m| m['line_number'] }).must_equal [1, 4]
    end

    it 'treats the search term as literal text when regex is unticked' do
      post '/nodes/conf_search.json', search_in_conf_textbox: 'ge-0/0/.',
                                      search_regex_checkbox: 'off'

      result = JSON.parse(last_response.body)
      _(result.length).must_equal 0
    end

    it 'pre-fills the search form with the term and checkbox state' do
      post '/nodes/conf_search', search_in_conf_textbox: 'description'

      _(last_response.ok?).must_equal true
      _(last_response.body).must_include "value='description'"
      _(last_response.body).must_include "name='search_regex_checkbox'"
      _(last_response.body).must_include 'checked'
    end

    it 'keeps the regex checkbox unticked after a literal search' do
      post '/nodes/conf_search', search_in_conf_textbox: 'description',
                                 search_regex_checkbox: 'off'

      _(last_response.ok?).must_equal true
      _(last_response.body).wont_include 'checked'
    end
  end

  describe '/nodes/:filter/*' do
    it 'shows all nodes of a group' do
      get '/nodes/group/group1.json'

      _(last_response.ok?).must_equal true
      result = JSON.parse(last_response.body)
      _(result.length).must_equal 2
    end
    it 'shows all nodes of a group with /' do
      get '/nodes/group/gr/oup1.json'

      _(last_response.ok?).must_equal true
      result = JSON.parse(last_response.body)
      _(result.length).must_equal 1
    end
    it 'shows all nodes of a model' do
      get '/nodes/model/ios.json'

      _(last_response.ok?).must_equal true
      result = JSON.parse(last_response.body)
      _(result.length).must_equal 4
    end
    it 'shows all nodes of the default group' do
      get '/nodes/group/default.json'

      _(last_response.ok?).must_equal true
      result = JSON.parse(last_response.body)
      _(result.length).must_equal 3
    end
  end
end

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  describe '/nodes/conf_search.?:format?' do
    it 'redirects to /nodes when the search is empty' do
      post '/nodes/conf_search', search_in_conf_textbox: ''

      _(last_response.redirect?).must_equal true
    end

    it 'rejects an invalid regular expression' do
      post '/nodes/conf_search.json', search_in_conf_textbox: '(',
                                      search_regex_checkbox: 'on'

      _(last_response.status).must_equal 400
      result = JSON.parse(last_response.body)
      _(result['error']).must_match(/Invalid regular expression/)
    end
  end
end
