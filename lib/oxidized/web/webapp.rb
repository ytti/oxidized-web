require 'sinatra/base'
require 'sinatra/url_for'
require 'tilt/haml'
require 'htmlentities'
module Oxidized
  module API
    require 'oxidized/web/version'
    require 'oxidized/web/helpers/conf_search'
    require 'oxidized/web/helpers/formatting'

    class WebApp < Sinatra::Base
      helpers Sinatra::UrlForHelper, Helpers::ConfSearch, Helpers::Formatting
      set :public_folder, proc { File.join(root, 'public') }
      # attr_quote: use double quotes for HTML attributes. Set explicitly so the
      # output is stable across Haml versions. Haml 7.3.0 changed the default
      # from "'" to '"' (haml/haml#1188); older versions still default to "'".
      set :haml, { escape_html: true, attr_quote: '"' }
      # Timeout in seconds for the config search regexp, to protect against
      # ReDoS. It limits each single regexp match on a config, not the whole
      # search. When one match takes longer, the whole search is aborted with
      # an error.
      # Regexp timeouts need Ruby >= 3.2; on older Rubies there is no timeout.
      set :conf_search_regexp_timeout, 1.0

      get '/' do
        redirect url_for('/nodes')
      end

      get '/favicon.ico' do
        redirect url_for('/images/favicon.ico')
      end

      # :filter can be "group" or "model"
      # URL: /nodes/group/<GroupName>[.json]
      # URL: /nodes/model/<ModelName>[.json]
      # an optional .json extension returns the data as JSON
      #
      # as GroupName can include /, we use splat to match its value
      # and extract the optional ".json" with route_parse
      get '/nodes/:filter/*' do
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

      get '/nodes.?:format?' do
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

      post '/nodes/conf_search.?:format?' do
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

      get '/nodes/stats.?:format?' do
        @data = {}
        nodes.each do |node|
          @data[node.name] = node.stats
        end
        out :stats
      end

      get '/reload.?:format?' do
        node = params[:node]
        node ? (nodes.load node) : nodes.load
        @data = node ? "reloaded #{node}" : 'reloaded list of nodes'
        out
      end

      # URL: /node/fetch/<group>/<node>.json
      # Gets the configuration of a node
      # <group> is optional. If no group is given, nil will be passed to oxidized
      # .json is optional. If given, will return the output in json format
      get '/node/fetch/?*?/:node' do
        node, @json = route_parse :node
        group = params['splat'].first
        group = nil if group.empty?
        begin
          @data = nodes.fetch node, group
        rescue NodeNotFound => e
          @data = e.message
        end
        out :text
      end

      # URL: /node/fetch/<group>/<node>[.json]
      # <group> is optional, and not used
      # .json is optional. If given, will return 'ok'
      # if not, it redirects to /nodes
      get '/node/next/?*?/:node' do
        node, @json = route_parse :node
        nodes.next node
        redirect url_for('/nodes') unless @json
        @data = 'ok'
        out
      end

      # use this to attach author/email/message to commit
      put '/node/next/?*?/:node' do
        node, @json = route_parse :node
        opt = JSON.parse request.body.read
        nodes.next node, opt
        redirect url_for('/nodes') unless @json
        @data = 'ok'
        out
      end

      get '/node/show/:node' do
        node, @json = route_parse :node
        @data = filter_node_vars(nodes.show(node))
        out :node
      end

      # display the versions of a node
      # URL: /node/version[.json]?node_full=<GroupName/NodeName>
      get '/node/version.?:format?' do
        @data = nil
        @group = nil
        @node = nil
        node_full = params[:node_full].to_s
        if node_full.include? '/'
          node_full = node_full.rpartition("/")
          @group = node_full[0]
          @node = node_full[2]
          @data = nodes.version @node, @group
        else
          @node = node_full
          @data = nodes.version @node, nil
        end
        out :versions
      end

      # show the blob of a version
      get '/node/version/view.?:format?' do
        node, @json = route_parse :node
        @info = {
          node: node,
          group: params[:group] || '',
          oid: params[:oid],
          time: Time.at(params[:epoch].to_i),
          num: params[:num]
        }

        the_data = nodes.get_version node, @info[:group].empty? ? nil : @info[:group], @info[:oid]
        if %w[json text].include?(params[:format])
          @data = the_data
        else
          utf8_encoded_content = convert_to_utf8(the_data)
          @data = HTMLEntities.new.encode(utf8_encoded_content)
        end
        out :version
      end

      # show diffs between 2 version
      get '/node/version/diffs' do
        node, @json = route_parse :node
        @data = nil
        @info = { node: node,
                  group: params[:group] || '',
                  oid: params[:oid],
                  time: Time.at(params[:epoch].to_i),
                  num: params[:num],
                  num2: (params[:num].to_i - 1) }
        group = nil
        group = @info[:group] if @info[:group] != ''
        @oids_dates = nodes.version node, group
        if params[:oid2]
          @info[:oid2] = params[:oid2]
          oid2 = nil
          num = @oids_dates.count + 1
          @oids_dates.each do |x|
            num -= 1
            next unless x[:oid].to_s == params[:oid2]

            oid2 = x[:oid]
            @info[:num2] = num
            break
          end
          @data = nodes.get_diff node, group, @info[:oid], oid2
        else
          @data = nodes.get_diff node, group, @info[:oid], nil
        end
        @stat = %w[null null]
        if @data != 'no diffs' && !@data.nil?
          @stat = @data[:stat]
          @data = @data[:patch]
        else
          @data = 'No diff available'
        end
        @diff = diff_view @data
        out :diffs
      end

      # used for diff between 2 distant commit
      post '/node/version/diffs' do
        redirect url_for("/node/version/diffs?node=#{params[:node]}&group=#{params[:group]}&oid=#{params[:oid]}&epoch=#{params[:epoch]}&num=#{params[:num]}&oid2=#{params[:oid2]}")
      end

      private

      def out(template = :text)
        if @json || (params[:format] == 'json')
          content_type :json
          if @data.is_a?(String)
            JSON.generate(@data.lines)
          else
            JSON.generate(@data)
          end
        elsif (template == :text) || (params[:format] == 'text')
          content_type :text
          @data
        else
          haml template, layout: true
        end
      end

      def nodes
        settings.nodes
      end

      # checks if param ends with .json
      # if so, returns param without ".json" and true
      # if not, returns param and false
      def route_parse(param)
        json = false
        e = if param.respond_to?(:to_str)
              param.split '.'
            else
              params[param].to_s.split '.'
            end
        if e.last == 'json'
          e.pop
          json = true
        end
        [e.join('.'), json]
      end

      def filter_node_vars(serialized_node)
        # Make a deep copy of the data, so we do not impact oxidized
        data = Marshal.load(Marshal.dump(serialized_node))
        # Make sure we work on strings (Oxidized <= 0.34.1 uses symbols)
        data[:vars] = data[:vars].transform_keys(&:to_s)

        hide_node_vars = settings.configuration[:hide_node_vars].map(&:to_s)
        if data[:vars].is_a?(Hash) && hide_node_vars&.any?
          hide_node_vars.each do |key|
            data[:vars][key] = '<hidden>' if data[:vars].has_key?(key)
          end
        end

        data
      end

      # set node last changed time to last version time
      # potential can be long operation
      def assign_mtime_from_versions(node)
        if node[:mtime] == 'unknown' || node[:mtime].nil?
          group = node[:group] == 'default' ? nil : node[:group]
          versions = nodes.version(node[:name], group)
          node[:mtime] = versions.first[:time] if versions.is_a?(Array) && !versions.empty? && versions.first[:time]
        end
        node
      end
    end
  end
end
