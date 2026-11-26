module Oxidized
  module API
    module Helpers
      # Statistics of the nodes
      module Stats
        private

        # Summary of the Oxidized::Node::Stats of a node for the stats page.
        # last_success/last_failure are a Time, 'never' or nil.
        #
        # The counters (successes, failures) count all runs, the history only
        # the last runs per status. A failure is any status but :success
        # (:no_connection, :fail, :timelimit...).
        def node_stats_summary(stats)
          successes = stats.successes
          failures = stats.failures
          history = stats.get || {}
          success_runs = history[:success] || []
          failure_runs = history.except(:counter, :success).flat_map do |status, runs|
            runs.map { |run| run.merge(status: status.to_s) }
          end

          last_success = success_runs.map { |run| run[:end] }.max
          last_failure_run = failure_runs.max_by { |run| run[:end] }
          last_failure = last_failure_run&.dig(:end)
          avg_times = [success_runs, failure_runs].reject(&:empty?).map do |runs|
            runs.sum { |run| run[:time] } / runs.size
          end
          avg_time = avg_times.empty? ? 0 : avg_times.sum / avg_times.size

          # status of the last run: 'success', the failure status or 'never'
          if last_success && last_failure
            status = last_success > last_failure ? 'success' : last_failure_run[:status]
          elsif last_success
            status = 'success'
            last_failure = 'never'
          else
            status = last_failure_run ? last_failure_run[:status] : 'never'
            last_success = 'never'
          end

          total_runs = successes + failures
          failure_rate = total_runs.zero? ? 0.0 : (failures / total_runs.to_f) * 100
          row_class = if failure_rate >= 75
                        'danger'
                      elsif failure_rate >= 50
                        'warning'
                      else
                        ''
                      end

          { total_runs: total_runs, failures: failures, failure_rate: failure_rate, avg_time: avg_time,
            status: status, last_success: last_success, last_failure: last_failure, row_class: row_class }
        end
      end
    end
  end
end
