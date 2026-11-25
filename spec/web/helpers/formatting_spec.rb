require_relative '../../spec_helper'

# Test the helper methods of Oxidized::API::Helpers::Formatting

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  before do
    @webapp = Oxidized::API::WebApp.new
  end

  describe 'convert_to_utf8' do
    it 'cannot work with binary data' do
      # private method => we must use send
      result = @webapp.helpers.send(:convert_to_utf8, "\xff\x42 binary content\x00")
      _(result).must_equal 'The text contains binary values - cannot display'
    end
  end

  describe 'diff_view' do
    it 'cannot work with binary data' do
      # private method => we must use send
      result = @webapp.helpers.send(:diff_view, "\xff\x42 binary content\x00")
      _(result[:old_diff]).must_equal ['The text contains binary values - cannot display']
      _(result[:new_diff]).must_equal ['The text contains binary values - cannot display']
    end

    it 'aligns added and removed lines with nil' do
      result = @webapp.helpers.send(:diff_view, " a\n-old\n+new1\n+new2\n")
      _(result[:old_diff]).must_equal [" a\n", "-old\n", nil]
      _(result[:new_diff]).must_equal [" a\n", "+new1\n", "+new2\n"]
    end
  end

  describe 'diff_lines_html' do
    it 'escapes the lines and renders nil as an empty line' do
      result = @webapp.helpers.send(:diff_lines_html, ["-<a> & 'b'\n", nil, "@@ -1 +1 @@\n"])
      _(result).must_equal "<div class=\"deleted\">-&lt;a&gt; &amp; &#39;b&#39;\n</div>" \
                           "<div>&nbsp;\n</div>" \
                           "<div class=\"diff-index\">@@ -1 +1 @@\n</div>"
    end
  end
end
