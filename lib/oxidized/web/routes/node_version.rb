module Oxidized
  module API
    module Routes
      # Versions and diffs of a node
      module NodeVersion
        def self.registered(app)
          # display the versions of a node
          # URL: /node/version[.json]?node_full=<GroupName/NodeName>
          app.get '/node/version.?:format?' do
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
          app.get '/node/version/view.?:format?' do
            node, @json = route_parse :node
            @info = {
              node: node,
              group: params[:group] || '',
              oid: params[:oid],
              time: Time.at(params[:epoch].to_i),
              num: params[:num]
            }

            the_data = nodes.get_version node, @info[:group].empty? ? nil : @info[:group], @info[:oid]
            @data = %w[json text].include?(params[:format]) ? the_data : convert_to_utf8(the_data)
            out :version
          end

          # show diffs between 2 version
          app.get '/node/version/diffs' do
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
          app.post '/node/version/diffs' do
            query = url_query(params.slice('node', 'group', 'oid', 'epoch', 'num', 'oid2'))
            redirect url_for("/node/version/diffs?#{query}")
          end
        end
      end
    end
  end
end
