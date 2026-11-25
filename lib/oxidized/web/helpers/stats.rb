module Oxidized
  module API
    module Helpers
      # Statistics of the nodes
      module Stats
        private

        # Summary of the Oxidized::Node::Stats of a node for the stats page.
        # last_success/last_failure are a Time, 'never' or nil.
        def node_stats_summary(stats)
          successes = stats.successes
          failures = stats.failures
          success = stats.get(:success)
          no_connection = stats.get(:no_connection)

          last_success = success&.last&.dig(:end)
          last_failure = no_connection&.last&.dig(:end)
          avg_success_time = success ? success.sum { |x| x[:time] } / successes : 0
          avg_failure_time = no_connection ? no_connection.sum { |x| x[:time] } / failures : 0
          avg_times = [avg_success_time, avg_failure_time].select(&:positive?)
          avg_time = avg_times.empty? ? 0 : avg_times.sum / avg_times.size

          if last_success && last_failure
            status = last_success > last_failure ? 'success' : 'no_connection'
          elsif last_success
            status = 'success'
            last_failure = 'never'
          else
            status = 'no_connection'
            last_success = 'never'
          end

          total_runs = successes + failures
          failure_rate = (failures / total_runs.to_f) * 100
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
