require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/url_for'
require 'tilt/haml'
require 'htmlentities'
require 'charlock_holmes'
module Oxidized
  module API
    require 'oxidized/web/version'

    class WebApp < Sinatra::Base
      helpers Sinatra::UrlForHelper
      set :public_folder, proc { File.join(root, 'public') }
      set :haml, { escape_html: false }

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
          node
        end
        out :nodes
      end

      get '/nodes.?:format?' do
        @data = nodes.list.map do |node|
          node[:status] = 'never'
          node[:time]   = 'never'
          node[:group]  = 'default' unless node[:group]
          if node[:last]
            node[:status] = node[:last][:status]
            node[:time]   = node[:last][:end]
          end
          node
        end
        out :nodes
      end

      post '/nodes/conf_search.?:format?' do
        @search_term = params[:search_in_conf_textbox].to_s
        redirect url_for('/nodes') if @search_term.empty?

        # regex search is the default; the search form on the results page
        # sends 'off' (via a hidden field) when the checkbox is unticked
        @regex_search = params[:search_regex_checkbox] != 'off'
        # preserve the existing case-sensitive default; the search form sends
        # 'off' (via a hidden field) when the checkbox is unticked
        @case_sensitive_search = params[:search_case_sensitive_checkbox] != 'off'
        @nodes_match = []
        begin
          pattern = @regex_search ? @search_term : Regexp.escape(@search_term)
          options = @case_sensitive_search ? 0 : Regexp::IGNORECASE
          @to_research = Regexp.new pattern, options
        rescue RegexpError => e
          @error = "Invalid regular expression: #{e.message}"
        end

        if @error
          status 400
          @data = { error: @error }
        else
          nodes.list.each do |n|
            node, @json = route_parse n[:name]
            config = convert_to_utf8 nodes.fetch(node, n[:group]).to_s
            matches = config_search_matches config, @to_research
            next if matches.empty?

            @nodes_match.push({ node: n[:name], full_name: n[:full_name],
                                matches: matches })
          end
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
        node_full = params[:node_full]
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
          group: params[:group],
          oid: params[:oid],
          time: Time.at(params[:epoch].to_i),
          num: params[:num]
        }

        the_data = nodes.get_version node, @info[:group], @info[:oid]
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
                  group: params[:group],
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
          @data = nodes.get_diff node, @info[:group], @info[:oid], oid2
        else
          @data = nodes.get_diff node, @info[:group], @info[:oid], nil
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

      # Taken von Haml 5.0, so it still works in 6.0
      HTML_ESCAPE = { '&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;', "'" => '&#39;' }.freeze
      HTML_ESCAPE_ONCE_REGEX = /['"><]|&(?!(?:[a-zA-Z]+|#(?:\d+|[xX][0-9a-fA-F]+));)/

      # lines of context shown around each config search match
      CONF_SEARCH_CONTEXT_LINES = 2

      private

      def out(template = :text)
        if @json || (params[:format] == 'json')
          if @data.is_a?(String)
            json @data.lines
          else
            json @data
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
              params[param].split '.'
            end
        if e.last == 'json'
          e.pop
          json = true
        end
        [e.join('.'), json]
      end

      # Give one entry per distinct region of the config matching +regexp+.
      # The regexp runs against the whole config, so patterns that span lines
      # (\n, \R, [\s\S], /m with .) and string anchors (\A, \z) work. Lines are
      # only used to build the snippet. Context windows that overlap or touch
      # are merged so nearby matches do not return duplicate snippets.
      # +line_number+ remains the first match for API compatibility;
      # +line_numbers+ contains every line a match touches in the region.
      # Each snippet line has +highlights+: [from, to) character ranges of the
      # match on that line.
      def config_search_matches(config, regexp)
        lines = config.lines
        return [] if lines.empty?

        line_starts = lines.each_with_object([0]) { |line, starts| starts << (starts.last + line.length) }
        lines = lines.map(&:chomp)
        hits = config_search_hits(config, regexp, line_starts)
        return [] if hits.empty?

        highlights = config_search_highlights(hits, lines, line_starts)
        config_search_regions(hits, lines.length).map do |region|
          snippet = (region[:from]..region[:to]).map do |index|
            { number: index + 1, text: lines[index], match: highlights.has_key?(index),
              highlights: highlights.fetch(index, []) }
          end
          line_numbers = snippet.select { |line| line[:match] }.map { |line| line[:number] }
          { line_number: line_numbers.first, line_numbers: line_numbers, snippet: snippet }
        end
      end

      # Every match of +regexp+ in +config+, with its character offsets and
      # the first and last line it touches
      def config_search_hits(config, regexp, line_starts)
        config.to_enum(:scan, regexp).map do
          from, to = Regexp.last_match.offset(0)
          first = config_search_line_at(line_starts, from)
          # a zero-width match sits on one line; otherwise the line of the
          # last matched character, so a match ending in "\n" stays on its line
          last = to > from ? config_search_line_at(line_starts, to - 1) : first
          { from: from, to: to, first: first, last: last }
        end
      end

      # Index of the line that holds character +offset+
      def config_search_line_at(line_starts, offset)
        (line_starts.bsearch_index { |start| start > offset } || (line_starts.length - 1)) - 1
      end

      # Map of line index => [from, to) ranges of matched text on that line.
      # A line is a key if any match touches it, even when only its newline
      # or a zero-width position matched.
      def config_search_highlights(hits, lines, line_starts)
        hits.each_with_object({}) do |hit, highlights|
          (hit[:first]..hit[:last]).each do |index|
            ranges = (highlights[index] ||= [])
            from = [hit[:from] - line_starts[index], 0].max
            to = [hit[:to] - line_starts[index], lines[index].length].min
            ranges << [from, to] if to > from
          end
        end
      end

      # Line ranges to show: each match plus context, merged when they
      # overlap or touch
      def config_search_regions(hits, line_count)
        hits.each_with_object([]) do |hit, merged|
          from = [hit[:first] - CONF_SEARCH_CONTEXT_LINES, 0].max
          to = [hit[:last] + CONF_SEARCH_CONTEXT_LINES, line_count - 1].min

          if merged.any? && from <= merged.last[:to] + 1
            merged.last[:to] = [merged.last[:to], to].max
          else
            merged << { from: from, to: to }
          end
        end
      end

      # HTML-escape +text+, wrapping each [from, to) range in <mark>
      def highlight_ranges(text, ranges)
        html = +''
        pos = 0
        ranges.each do |from, to|
          html << escape_once(text[pos...from])
          html << "<mark>#{escape_once(text[from...to])}</mark>"
          pos = to
        end
        html << escape_once(text[pos..])
      end

      # HTML for one config search snippet: line-numbered text with the
      # matches highlighted
      def snippet_html(match)
        width = match[:snippet].last[:number].to_s.length
        match[:snippet].map do |line|
          "#{line[:number].to_s.rjust(width)}: #{highlight_ranges(line[:text], line[:highlights])}"
        end.join("\n")
      end

      # give the time elapsed between now and a date (Time object)
      def time_from_now(date)
        return "no time specified" if date.nil?

        raise "time_from_now needs a Time object" unless date.instance_of? Time

        t = (Time.now - date).to_i
        mm, ss = t.divmod(60)
        hh, mm = mm.divmod(60)
        dd, hh = hh.divmod(24)
        if dd.positive?
          "#{dd} days #{hh} hours ago"
        elsif hh.positive?
          "#{hh} hours #{mm} min ago"
        else
          "#{mm} min #{ss} sec ago"
        end
      end

      # method the give diffs in separate view (the old and the new) as in github
      def diff_view(diff)
        old_diff = []
        new_diff = []

        utf8_encoded_content = convert_to_utf8(diff)
        HTMLEntities.new.encode(utf8_encoded_content).each_line do |line|
          if /^\+/.match(line)
            new_diff.push(line)
          elsif /^-/.match(line)
            old_diff.push(line)
          else
            new_diff.push(line)
            old_diff.push(line)
          end
        end

        length_o = old_diff.count
        length_n = new_diff.count
        (0..[length_o, length_n].max).each do |i|
          break if i > [length_o, length_n].min

          if /^-.*/.match(old_diff[i]) && !/^\+.*/.match(new_diff[i])
            # tag removed latter to add color syntax
            # ugly way to avoid asymmetry if at display the line takes 2 line on the screen
            insert = "&nbsp;\n"
            new_diff.insert(i, insert)
            length_n += 1
          elsif !/^-.*/.match(old_diff[i]) && /^\+.*/.match(new_diff[i])
            insert = "&nbsp;\n"
            old_diff.insert(i, insert)
            length_o += 1
          end
        end
        { old_diff: old_diff, new_diff: new_diff }
      end

      def escape_once(text)
        text = text.to_s
        text.gsub(HTML_ESCAPE_ONCE_REGEX, HTML_ESCAPE)
      end

      def convert_to_utf8(text)
        detection = ::CharlockHolmes::EncodingDetector.detect(text)
        if detection[:type] == :text
          ::CharlockHolmes::Converter.convert text, detection[:encoding], 'UTF-8'
        else
          'The text contains binary values - cannot display'
        end
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
    end
  end
end
