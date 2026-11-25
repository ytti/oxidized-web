require_relative '../../spec_helper'

# Test the helper methods of Oxidized::API::Helpers::Stats

describe Oxidized::API::WebApp do
  before do
    @webapp = Oxidized::API::WebApp.new
    @t = Time.parse('2025-02-05 19:49:00 +0100')
  end

  # history: runs per status, as returned by Oxidized::Node::Stats#get
  def node_stats(successes:, failures:, history: {})
    stats = mock('Oxidized::Node::Stats')
    stats.stubs(:successes).returns(successes)
    stats.stubs(:failures).returns(failures)
    stats.stubs(:get).with.returns({ counter: { success: successes } }.merge(history))
    stats
  end

  def summary(stats)
    # private method => we must use send
    @webapp.helpers.send(:node_stats_summary, stats)
  end

  describe 'node_stats_summary' do
    it 'summarizes a node with successes and failures' do
      stats = node_stats(successes: 2, failures: 1,
                         history: { success: [{ end: @t, time: 2.0 }, { end: @t + 60, time: 4.0 }],
                                    no_connection: [{ end: @t - 60, time: 1.0 }] })

      _(summary(stats)).must_equal(
        { total_runs: 3, failures: 1, failure_rate: (1 / 3.0) * 100, avg_time: 2.0, status: 'success',
          last_success: @t + 60, last_failure: @t - 60, row_class: '' }
      )
    end

    it 'shows no_connection when the last failure is newer than the last success' do
      stats = node_stats(successes: 1, failures: 1,
                         history: { success: [{ end: @t - 60, time: 2.0 }],
                                    no_connection: [{ end: @t, time: 4.0 }] })

      result = summary(stats)
      _(result[:status]).must_equal 'no_connection'
      _(result[:avg_time]).must_equal 3.0
      _(result[:row_class]).must_equal 'warning'
    end

    it 'shows never as last failure for a node without failures' do
      stats = node_stats(successes: 1, failures: 0, history: { success: [{ end: @t, time: 1.5 }] })

      result = summary(stats)
      _(result[:status]).must_equal 'success'
      _(result[:last_success]).must_equal @t
      _(result[:last_failure]).must_equal 'never'
      _(result[:avg_time]).must_equal 1.5
      _(result[:failure_rate]).must_equal 0.0
    end

    it 'shows never as last success for a node without successes' do
      stats = node_stats(successes: 0, failures: 2,
                         history: { no_connection: [{ end: @t, time: 3.0 }, { end: @t, time: 5.0 }] })

      result = summary(stats)
      _(result[:status]).must_equal 'no_connection'
      _(result[:last_success]).must_equal 'never'
      _(result[:last_failure]).must_equal @t
      _(result[:avg_time]).must_equal 4.0
      _(result[:row_class]).must_equal 'danger'
    end

    it 'averages over the runs in the history, not over all runs counted' do
      # the history only keeps the last runs, the counters count all of them
      stats = node_stats(successes: 100, failures: 50,
                         history: { success: [{ end: @t, time: 2.0 }, { end: @t, time: 4.0 }],
                                    no_connection: [{ end: @t - 60, time: 6.0 }] })

      result = summary(stats)
      _(result[:avg_time]).must_equal 4.5
      _(result[:total_runs]).must_equal 150
      _(result[:failures]).must_equal 50
    end

    it 'counts every status but success as a failure' do
      stats = node_stats(successes: 1, failures: 3,
                         history: { success: [{ end: @t - 120, time: 1.0 }],
                                    no_connection: [{ end: @t - 60, time: 2.0 }],
                                    fail: [{ end: @t, time: 4.0 }],
                                    timelimit: [{ end: @t - 30, time: 6.0 }] })

      result = summary(stats)
      _(result[:last_failure]).must_equal @t
      _(result[:status]).must_equal 'no_connection'
      _(result[:avg_time]).must_equal 2.5
    end

    it 'handles a node that has not run yet' do
      stats = mock('Oxidized::Node::Stats')
      stats.stubs(:successes).returns(0)
      stats.stubs(:failures).returns(0)
      stats.stubs(:get).returns(nil)

      _(summary(stats)).must_equal(
        { total_runs: 0, failures: 0, failure_rate: 0.0, avg_time: 0, status: 'no_connection',
          last_success: 'never', last_failure: nil, row_class: '' }
      )
    end

    it 'works with the Oxidized::Node::Stats of oxidized' do
      asetus = Asetus.new(name: 'oxidized', load: false)
      asetus.cfg.stats.history_size = 2
      Oxidized.stubs(:config).returns(asetus.cfg)
      job = Struct.new(:status, :start, :end, :time)

      stats = Oxidized::Node::Stats.new
      6.times { |i| stats.add(job.new(:success, @t, @t + i, i.to_f)) }
      stats.add(job.new(:fail, @t, @t + 3.5, 8.0))

      result = summary(stats)
      _(result[:total_runs]).must_equal 7
      _(result[:failures]).must_equal 1
      _(result[:last_success]).must_equal @t + 5
      _(result[:last_failure]).must_equal @t + 3.5
      _(result[:status]).must_equal 'success'
      # average of the last success runs in the history (3, 4 and 5 s) and the failure run (8 s)
      _(result[:avg_time]).must_equal 6.0
    end
  end
end
