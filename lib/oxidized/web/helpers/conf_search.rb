require 'htmlentities'

module Oxidized
  module API
    module Helpers
      # Config search over the configs of all nodes
      module ConfSearch
        # lines of context shown around each config search match
        CONF_SEARCH_CONTEXT_LINES = 2
        # snippets shown per node by default, and the choices offered in the
        # search form (0 = all)
        CONF_SEARCH_MAX_MATCHES_DEFAULT = 1
        CONF_SEARCH_MAX_MATCHES_OPTIONS = [1, 5, 20, 100, 0].freeze

        private

        # Search the configs of all nodes (or only the node with the full name
        # +search_node+) with +regexp+ and return the matching nodes with at
        # most +limit+ snippets each (0 = all)
        def conf_search_nodes(regexp, limit, search_node = nil)
          nodes.list.filter_map do |n|
            next if search_node && n[:full_name] != search_node

            config = nodes.fetch n[:name], n[:group]
            # no config available (e.g. output file returns nil)
            next unless config

            # binary configs cannot be searched
            config = text_to_utf8(config)
            next unless config

            matches = config_search_matches config, regexp
            next if matches.empty?

            # match_count is the number of snippets before the per-node limit
            { node: n[:name], full_name: n[:full_name],
              match_count: matches.length,
              matches: limit.zero? ? matches : matches.first(limit) }
          end
        end

        # Keyword arguments for Regexp.new setting the match timeout.
        # Regexp timeouts need Ruby >= 3.2
        # TODO: remove the check when Ruby < 3.2 is no longer supported
        def conf_search_regexp_timeout
          return {} unless Regexp.respond_to?(:timeout)

          { timeout: settings.conf_search_regexp_timeout }
        end

        # Regexp::TimeoutError only exists in Ruby >= 3.2
        def regexp_timeout_error?(error)
          defined?(Regexp::TimeoutError) && error.is_a?(Regexp::TimeoutError)
        end

        # Number of snippets to return per node from the +search_max_matches+
        # parameter: a non-negative integer, 0 meaning all. Anything else
        # (missing, not a number, negative) gives the default.
        def conf_search_max_matches(param)
          value = Integer(param.to_s, 10, exception: false)
          value && value >= 0 ? value : CONF_SEARCH_MAX_MATCHES_DEFAULT
        end

        # Choices for the snippets-per-node select, including a value outside
        # the predefined options that was requested directly (e.g. via the API)
        def conf_search_max_matches_options
          options = CONF_SEARCH_MAX_MATCHES_OPTIONS | [@max_matches]
          options.sort_by { |n| n.zero? ? Float::INFINITY : n }
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
          # most configs do not match; skip building the line index for them
          return [] unless regexp.match?(config)

          lines = config.lines
          return [] if lines.empty?

          line_starts = lines.each_with_object([0]) { |line, starts| starts << (starts.last + line.length) }
          lines = lines.map(&:chomp)
          hits = config_search_hits(config, regexp, line_starts)

          highlights = config_search_highlights(hits, lines, line_starts)
          config_search_regions(hits, lines.length).map do |region|
            snippet = (region[:from]..region[:to]).map do |index|
              { number: index + 1, text: lines[index], match: highlights.has_key?(index),
                highlights: highlights.fetch(index, []) }
            end
            line_numbers = snippet.filter_map { |line| line[:number] if line[:match] }
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
          coder = HTMLEntities.new
          html = +''
          pos = 0
          ranges.each do |from, to|
            html << coder.encode(text[pos...from])
            html << "<mark>#{coder.encode(text[from...to])}</mark>"
            pos = to
          end
          html << coder.encode(text[pos..])
        end

        # HTML for one config search snippet: line-numbered text with the
        # matches highlighted
        def snippet_html(match)
          width = match[:snippet].last[:number].to_s.length
          match[:snippet].map do |line|
            "#{line[:number].to_s.rjust(width)}: #{highlight_ranges(line[:text], line[:highlights])}"
          end.join("\n")
        end
      end
    end
  end
end
