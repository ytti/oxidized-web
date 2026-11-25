module Oxidized
  module API
    module Routes
      # Node list, config search and statistics
      module Nodes
        def self.registered(app)
          # :filter can be "group" or "model"
          # URL: /nodes/group/<GroupName>[.json]
          # URL: /nodes/model/<ModelName>[.json]
          # an optional .json extension returns the data as JSON
          #
          # as GroupName can include /, we use splat to match its value
          # and extract the optional ".json" with route_parse
          app.get '/nodes/:filter/*' do
            value, @json = route_parse params[:splat].first
            mtime_from_versions = settings.configuration[:mtime_from_versions]
            @data = nodes.list.select do |node|
              next unless node[params[:filter].to_sym] == value ||
                          (
                            params[:filter].to_sym == :group &&
                            node[params[:filter].to_sym].nil? &&
                            value.to_sym == :default
                          )

              node[:status] = 'never'
              node[:time]   = 'never'
              node[:group]  = 'default' unless node[:group]
              if node[:last]
                node[:status] = node[:last][:status]
                node[:time]   = node[:last][:end]
              end
              assign_mtime_from_versions(node) if mtime_from_versions
              node
            end
            out :nodes
          end

          app.get '/nodes.?:format?' do
            mtime_from_versions = settings.configuration[:mtime_from_versions]
            @data = nodes.list.map do |node|
              node[:status] = 'never'
              node[:time]   = 'never'
              node[:group]  = 'default' unless node[:group]
              if node[:last]
                node[:status] = node[:last][:status]
                node[:time]   = node[:last][:end]
              end
              assign_mtime_from_versions(node) if mtime_from_versions
              node
            end
            out :nodes
          end

          app.post '/nodes/conf_search.?:format?' do
            # an empty search term shows the search page without results
            @search_term = params[:search_in_conf_textbox].to_s

            # regex search is the default; the search form on the results page
            # sends 'off' (via a hidden field) when the checkbox is unticked
            @regex_search = params[:search_regex_checkbox] != 'off'
            # preserve the existing case-sensitive default; the search form sends
            # 'off' (via a hidden field) when the checkbox is unticked
            @case_sensitive_search = params[:search_case_sensitive_checkbox] != 'off'
            # snippets returned per node; 0 returns all of them
            @max_matches = conf_search_max_matches params[:search_max_matches]
            # restrict the search to one node (by full_name) and return all of
            # its snippets; @max_matches is kept for the search form
            @search_node = params[:search_node].to_s
            @search_node = nil if @search_node.empty?
            limit = @search_node ? 0 : @max_matches
            @nodes_match = []
            begin
              pattern = @regex_search ? @search_term : Regexp.escape(@search_term)
              options = @case_sensitive_search ? 0 : Regexp::IGNORECASE
              regexp = Regexp.new pattern, options, **conf_search_regexp_timeout
            rescue RegexpError => e
              @error = "Invalid regular expression: #{e.message}"
            end

            unless @error || @search_term.empty?
              begin
                @nodes_match = conf_search_nodes regexp, limit, @search_node
              rescue StandardError => e
                raise unless regexp_timeout_error? e

                # abort the whole search on the first timeout
                @nodes_match = []
                @error = 'The regular expression took too long to evaluate, please simplify it'
              end
            end

            if @error
              status 400
              @data = { error: @error }
            else
              @data = @nodes_match
            end
            out :conf_search
          end

          app.get '/nodes/stats.?:format?' do
            @data = {}
            nodes.each do |node|
              @data[node.name] = node.stats
            end
            out :stats
          end
        end
      end
    end
  end
end
