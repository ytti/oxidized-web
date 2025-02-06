require_relative 'spec_helper'
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
  end
end
