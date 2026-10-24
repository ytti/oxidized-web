require_relative '../spec_helper'
require 'json'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  before do
    @nodes = mock('Oxidized::Nodes')
    @nodes.stubs(:list).returns(
      [{ name: 'sw4', ip: '10.10.10.10', model: 'ios', time: 'time', mtime: 'mtime' },
       { name: 'sw5', ip: '10.10.10.5',  model: 'ios', time: 'time', mtime: 'mtime' },
       { name: 'sw6', ip: '10.10.10.6',  model: 'ios', time: 'time', mtime: 'mtime' },
       { name: 'sw7', ip: '10.10.10.7',  model: 'ios', time: 'time', mtime: 'mtime', group: 'group1' },
       { name: 'sw8', ip: '10.10.10.8',  model: 'aos', time: 'time', mtime: 'mtime', group: 'group1' },
       { name: 'sw9', ip: '10.10.10.9',  model: 'aos', time: 'time', mtime: 'mtime', group: 'gr/oup1' }]
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

    it 'shows only data-backed latest backup counts in the inventory overview' do
      now = Time.at(1_750_000_000)
      @nodes.expects(:list).returns(
        [
          { name: 'edge-1', full_name: 'edge-1.example', ip: '192.0.2.1', model: 'ios',
            group: 'core', time: now, mtime: now,
            last: { status: :success, end: now } },
          { name: 'edge-2', full_name: 'edge-2.example', ip: '192.0.2.2', model: 'routeros',
            group: 'branch', time: now, mtime: now,
            last: { status: :no_connection, end: now } },
          { name: 'edge-3', full_name: 'edge-3.example', ip: '192.0.2.3', model: 'ios',
            group: nil, time: 'never', mtime: now },
          { name: 'edge-4', full_name: 'edge-4.example', ip: '192.0.2.4', model: 'ios',
            group: nil, time: now, mtime: now, last: { status: :unknown, end: now } }
        ]
      )

      get '/nodes'

      _(last_response.ok?).must_equal true
      body = last_response.body
      _(body).must_match(/metric-card metric-card-neutral.*?metric-value[^>]*>4</m)
      _(body).must_match(/metric-card metric-card-success.*?metric-value[^>]*>1</m)
      _(body).must_match(/metric-card metric-card-danger.*?metric-value[^>]*>1</m)
      _(body).must_match(/metric-card metric-card-muted.*?metric-value[^>]*>1</m)
      _(body).must_include('Devices whose most recent run succeeded')
      _(body).must_include('Devices whose most recent run failed')
    end

    it 'lists the five devices with the newest modification timestamps' do
      nodes = (1..6).map do |number|
        timestamp = Time.at(number)
        { name: "change-#{number}", full_name: "change-#{number}.example",
          ip: "192.0.2.#{number}", model: 'ios', group: 'core',
          time: 'never', mtime: timestamp }
      end
      @nodes.expects(:list).returns(nodes)

      get '/nodes'

      _(last_response.ok?).must_equal true
      recent_changes = last_response.body.split('<div class="recent-changes-card">', 2).last
      positions = (2..6).to_a.reverse.map { |number| recent_changes.index("change-#{number}</a>") }
      _(positions).wont_include(nil)
      _(positions).must_equal positions.sort
      _(recent_changes).wont_include('change-1</a>')
    end

    it 'shows an empty state when there are no devices to list' do
      @nodes.expects(:list).returns([])

      get '/nodes'

      _(last_response.ok?).must_equal true
      _(last_response.body).must_match(/metric-card metric-card-neutral.*?metric-value[^>]*>0</m)
      _(last_response.body).must_include('No device modification timestamps are available.')
    end

    it 'shows an empty recent-changes state when listed devices have no modification timestamps' do
      @nodes.expects(:list).returns(
        [{ name: 'untimed-1', full_name: 'untimed-1.example', ip: '192.0.2.10',
           model: 'ios', group: 'core', time: 'never', mtime: nil },
         { name: 'untimed-2', full_name: 'untimed-2.example', ip: '192.0.2.11',
           model: 'ios', group: 'core', time: 'never', mtime: nil }]
      )

      get '/nodes'

      _(last_response.ok?).must_equal true
      _(last_response.body).must_include('No device modification timestamps are available.')
      _(last_response.body).wont_include('class="recent-change-row"')
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
