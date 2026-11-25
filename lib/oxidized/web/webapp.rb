require 'sinatra/base'
require 'sinatra/url_for'
require 'tilt/erubi'
require 'htmlentities'
module Oxidized
  module API
    require 'oxidized/web/version'
    require 'oxidized/web/helpers/conf_search'
    require 'oxidized/web/helpers/formatting'
    require 'oxidized/web/helpers/stats'
    require 'oxidized/web/routes/nodes'
    require 'oxidized/web/routes/node'
    require 'oxidized/web/routes/node_version'

    class WebApp < Sinatra::Base
      helpers Sinatra::UrlForHelper, Helpers::ConfSearch, Helpers::Formatting, Helpers::Stats
      set :public_folder, proc { File.join(root, 'public') }
      # <%= escapes HTML, <%== outputs it unescaped
      set :erb, { escape_html: true }
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

      get '/reload.?:format?' do
        node = params[:node]
        node ? (nodes.load node) : nodes.load
        @data = node ? "reloaded #{node}" : 'reloaded list of nodes'
        out
      end

      register Routes::Nodes, Routes::Node, Routes::NodeVersion

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
          erb template, layout: true
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
