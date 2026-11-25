require 'htmlentities'
require 'charlock_holmes'

module Oxidized
  module API
    module Helpers
      # Formatting of times, diffs and text for display
      module Formatting
        # Taken from Haml 5.0
        HTML_ESCAPE = { '&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;', "'" => '&#39;' }.freeze
        HTML_ESCAPE_ONCE_REGEX = /['"><]|&(?!(?:[a-zA-Z]+|#(?:\d+|[xX][0-9a-fA-F]+));)/

        private

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

        # HTML for one side of a diff_view, one <div> per line. The lines are
        # already HTML-encoded and may contain &nbsp; for alignment.
        def diff_lines_html(lines)
          lines.map do |line|
            css_class = if line.start_with?('+') then 'added'
                        elsif line.start_with?('-') then 'deleted'
                        elsif /^@@\s.*@@.*$/.match?(line) then 'diff-index'
                        end
            tag = css_class ? "<div class=\"#{css_class}\">" : '<div>'
            "#{tag}#{escape_once(line)}</div>"
          end.join
        end

        def escape_once(text)
          text = text.to_s
          text.gsub(HTML_ESCAPE_ONCE_REGEX, HTML_ESCAPE)
        end

        # Converts text to UTF-8, returns a placeholder message for binary data
        def convert_to_utf8(text)
          text_to_utf8(text) || 'The text contains binary values - cannot display'
        end

        # Converts text to UTF-8, returns nil for binary data
        def text_to_utf8(text)
          detection = ::CharlockHolmes::EncodingDetector.detect(text)
          return unless detection[:type] == :text

          ::CharlockHolmes::Converter.convert text, detection[:encoding], 'UTF-8'
        end
      end
    end
  end
end
