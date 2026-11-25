require_relative '../../spec_helper'
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
       { name: 'sw9', ip: '10.10.10.9',  model: 'aos', time: 'time', mtime: 'mtime', group: 'gr/oup1',
         full_name: 'gr/oup1/sw9' }]
    )
    app.set(:nodes, @nodes)
    app.set(:configuration, { hide_node_vars: [], mtime_from_versions: false })
  end

  describe '/nodes.?:format?' do
    it 'shows all nodes' do
      get '/nodes.json'

      _(last_response.ok?).must_equal true
      result = JSON.parse(last_response.body)
      _(result.length).must_equal 6
    end

    it 'lists the nodes with their links in the html view' do
      get '/nodes'

      _(last_response.ok?).must_equal true
      body = last_response.body
      _(body.scan(%r{<a href="/node/show/([^"]*)">\1</a>}).flatten).must_equal %w[sw4 sw5 sw6 sw7 sw8 sw9]
      _(body).must_include '<td>10.10.10.9</td>'
      _(body).must_include '<a href="/nodes/model/aos">aos</a>'
      _(body).must_include '<a href="/nodes/group/default">default</a>'
      _(body).must_include '<a href="/nodes/group/gr/oup1">gr/oup1</a>'
      _(body).must_include '<span style="visibility: hidden">never</span>'
      _(body).must_include 'href="/node/fetch/gr/oup1/sw9"'
      _(body).must_include 'href="/node/version?node_full=gr/oup1/sw9"'
      _(body).must_include 'href="/node/next/gr/oup1/sw9"'
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
