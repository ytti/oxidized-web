require_relative '../../spec_helper'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  before do
    @nodes = mock('Oxidized::Nodes')
    app.set(:nodes, @nodes)
  end

  describe 'get /nodes/stats' do
    it 'shows the statistics of each node in the html view' do
      t = Time.parse('2025-02-05 19:49:00 +0100')

      stats_ok = mock('Oxidized::Node::Stats')
      stats_ok.stubs(:successes).returns(2)
      stats_ok.stubs(:failures).returns(1)
      stats_ok.stubs(:get).with(:success).returns([{ end: t, time: 2.0 }, { end: t + 60, time: 4.0 }])
      stats_ok.stubs(:get).with(:no_connection).returns([{ end: t - 60, time: 1.0 }])
      node_ok = mock('Oxidized::Node')
      node_ok.stubs(:name).returns('sw5')
      node_ok.stubs(:stats).returns(stats_ok)

      stats_ko = mock('Oxidized::Node::Stats')
      stats_ko.stubs(:successes).returns(0)
      stats_ko.stubs(:failures).returns(2)
      stats_ko.stubs(:get).with(:success).returns(nil)
      stats_ko.stubs(:get).with(:no_connection).returns([{ end: t, time: 3.0 }, { end: t, time: 5.0 }])
      node_ko = mock('Oxidized::Node')
      node_ko.stubs(:name).returns('sw6')
      node_ko.stubs(:stats).returns(stats_ko)

      @nodes.stubs(:each).multiple_yields([node_ok], [node_ko])

      get '/nodes/stats'

      _(last_response.ok?).must_equal true
      body = last_response.body
      _(body).must_include 'id="statsTable"'
      _(body).must_match(%r{<td>sw5</td>\s*<td>3</td>\s*<td>1</td>\s*<td>33.33%</td>\s*<td>2.00</td>})
      _(body).must_include '<span style="visibility: hidden">success</span>'
      _(body).must_match(%r{<td(?=[^>]*\bclass="time")(?=[^>]*\bepoch="1738781400")[^>]*>2025-02-05 19:50:00 \+0100</td>})
      _(body).must_match(%r{<td(?=[^>]*\bclass="time")(?=[^>]*\bepoch="1738781280")[^>]*>2025-02-05 19:48:00 \+0100</td>})

      _(body).must_match(%r{<tr class="danger">\s*<td>sw6</td>\s*<td>2</td>\s*<td>2</td>\s*<td>100.00%</td>\s*<td>4.00</td>})
      _(body).must_include '<span style="visibility: hidden">no_connection</span>'
      _(body).must_match(%r{<td(?=[^>]*\bclass="time")(?=[^>]*\bepoch="0")[^>]*>never</td>})
    end
  end
end
