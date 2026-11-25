module Oxidized
  module API
    module Routes
      # Fetch, queue and show a single node
      module Node
        def self.registered(app)
          # URL: /node/fetch/<group>/<node>.json
          # Gets the configuration of a node
          # <group> is optional. If no group is given, nil will be passed to oxidized
          # .json is optional. If given, will return the output in json format
          app.get '/node/fetch/?*?/:node' do
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
          app.get '/node/next/?*?/:node' do
            node, @json = route_parse :node
            nodes.next node
            redirect url_for('/nodes') unless @json
            @data = 'ok'
            out
          end

          # use this to attach author/email/message to commit
          app.put '/node/next/?*?/:node' do
            node, @json = route_parse :node
            opt = JSON.parse request.body.read
            nodes.next node, opt
            redirect url_for('/nodes') unless @json
            @data = 'ok'
            out
          end

          app.get '/node/show/:node' do
            node, @json = route_parse :node
            @data = filter_node_vars(nodes.show(node))
            out :node
          end
        end
      end
    end
  end
end
