require_relative '../../spec_helper'

# Test the helper methods of Oxidized::API::Helpers::Stats

describe Oxidized::API::WebApp do
  before do
    @webapp = Oxidized::API::WebApp.new
    @t = Time.parse('2025-02-05 19:49:00 +0100')
  end

  def node_stats(successes:, failures:, success: nil, no_connection: nil)
    stats = mock('Oxidized::Node::Stats')
    stats.stubs(:successes).returns(successes)
    stats.stubs(:failures).returns(failures)
    stats.stubs(:get).with(:success).returns(success)
    stats.stubs(:get).with(:no_connection).returns(no_connection)
    stats
  end

  def summary(stats)
    # private method => we must use send
    @webapp.helpers.send(:node_stats_summary, stats)
  end

  describe 'node_stats_summary' do
    it 'summarizes a node with successes and failures' do
      stats = node_stats(successes: 2, failures: 1,
                         success: [{ end: @t, time: 2.0 }, { end: @t + 60, time: 4.0 }],
                         no_connection: [{ end: @t - 60, time: 1.0 }])

      _(summary(stats)).must_equal(
        { total_runs: 3, failures: 1, failure_rate: (1 / 3.0) * 100, avg_time: 2.0, status: 'success',
          last_success: @t + 60, last_failure: @t - 60, row_class: '' }
      )
    end

    it 'shows no_connection when the last failure is newer than the last success' do
      stats = node_stats(successes: 1, failures: 1,
                         success: [{ end: @t - 60, time: 2.0 }],
                         no_connection: [{ end: @t, time: 4.0 }])

      result = summary(stats)
      _(result[:status]).must_equal 'no_connection'
      _(result[:avg_time]).must_equal 3.0
      _(result[:row_class]).must_equal 'warning'
    end

    it 'shows never as last failure for a node without failures' do
      stats = node_stats(successes: 1, failures: 0, success: [{ end: @t, time: 1.5 }])

      result = summary(stats)
      _(result[:status]).must_equal 'success'
      _(result[:last_success]).must_equal @t
      _(result[:last_failure]).must_equal 'never'
      _(result[:avg_time]).must_equal 1.5
      _(result[:failure_rate]).must_equal 0.0
    end

    it 'shows never as last success for a node without successes' do
      stats = node_stats(successes: 0, failures: 2, no_connection: [{ end: @t, time: 3.0 }, { end: @t, time: 5.0 }])

      result = summary(stats)
      _(result[:status]).must_equal 'no_connection'
      _(result[:last_success]).must_equal 'never'
      _(result[:last_failure]).must_equal @t
      _(result[:avg_time]).must_equal 4.0
      _(result[:row_class]).must_equal 'danger'
    end
  end
end
