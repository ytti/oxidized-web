require_relative '../../spec_helper'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  before do
    @nodes = mock('Oxidized::Nodes')
    app.set(:nodes, @nodes)
  end

  describe 'get /node/version.?:format?' do
    before do
      @versions = [
        { oid: "C006", time: Time.parse("2025-02-05 19:49:00 +0100") },
        { oid: "C003", time: Time.parse("2025-02-05 19:03:00 +0100") },
        { oid: "C001", time: Time.parse("2025-02-05 19:01:00 +0100") }
      ]
    end

    it 'fetches all versions of a node without a group' do
      @nodes.expects(:version).with('sw5', nil).returns(@versions)

      get '/node/version?node_full=sw5'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?(
          "<tr>\n<td>3</td>\n<td class=\"time\" epoch=\"1738781340\">" \
          "2025-02-05 19:49:00 +0100</td>\n"
        )).must_equal true

      _(last_response.body.include?(
          "href=\"/node/version/view?node=sw5&amp;group=&amp;oid=C006&amp;" \
          "epoch=1738781340&amp;num=3\" title=\"configuration\">"
        )).must_equal true
      _(last_response.body.include?(
          "href=\"/node/version/diffs?node=sw5&amp;group=&amp;oid=C006&amp;" \
          "epoch=1738781340&amp;num=3\" title=\"Compare with previous version\">"
        )).must_equal true
      _(last_response.body.include?(
          "href=\"/node/version/view?node=sw5&amp;group=&amp;oid=C001&amp;" \
          "epoch=1738778460&amp;num=1\" title=\"configuration\">"
        )).must_equal true
      # Compare to the version previous 1 is not possible, so don't display it
      _(last_response.body.include?(
          "href=\"/node/version/diffs?node=sw5&amp;group=&amp;oid=C001&amp;" \
          "epoch=1738778460&amp;num=1\" title=\"Compare with previous version\">"
        )).must_equal false
    end

    it 'fetches all versions of a node with a group' do
      @nodes.expects(:version).with('sw5', 'group1').returns(@versions)

      get '/node/version?node_full=group1/sw5'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?(
          "<tr>\n<td>3</td>\n<td class=\"time\" epoch=\"1738781340\">" \
          "2025-02-05 19:49:00 +0100</td>\n"
        )).must_equal true
    end

    it 'fetches all versions of a node with a group with /' do
      @nodes.expects(:version).with('sw5', 'gr/oup1').returns(@versions)

      get '/node/version?node_full=gr/oup1/sw5'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?(
          "<tr>\n<td>3</td>\n<td class=\"time\" epoch=\"1738781340\">" \
          "2025-02-05 19:49:00 +0100</td>\n"
        )).must_equal true
    end

    it 'returns 200 when node_full is absent (no NoMethodError)' do
      @nodes.expects(:version).with('', nil).returns([])

      get '/node/version'
      _(last_response.ok?).must_equal true
    end
  end

  describe 'get /node/version/view.?:format?' do
    it 'fetches a previous version from git' do
      @nodes.expects(:get_version).with('sw5', nil, 'c8aa93cab5').returns('Old configuration of sw5')

      get '/node/version/view?node=sw5&group=&oid=c8aa93cab5&epoch=1738781340&num=2'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?('Old configuration of sw5')).must_equal true
      # The test needs to pass in any timezone, so we use Time.parse to get the
      # right string
      _(last_response.body.include?(
          "Date of version:\n" \
          "<span class=\"time\" epoch=\"1738781340\">" \
          "#{Time.at(1738781340)}</span>"
        )).must_equal true
    end

    it 'shows the configuration verbatim in a pre block' do
      configuration = "hostname sw5\n  description a & b &amp; <c>\n"
      @nodes.expects(:get_version).with('sw5', 'my/group', 'c8aa93cab5').returns(configuration)

      get '/node/version/view?node=sw5&group=my/group&oid=c8aa93cab5&epoch=1738781340&num=2'
      _(last_response.ok?).must_equal true
      body = last_response.body
      _(body).must_match(
        %r{<pre[^>]*>hostname sw5\n  description a &amp; b &amp;amp; &lt;c&gt;\n</pre>}
      )
      _(body).must_include '<a href="/node/version?node_full=my/group/sw5">versions</a>'
      _(body).must_include '<b>sw5</b>'
      _(body).must_include(
        'href="/node/version/view?node=sw5&amp;group=my/group&amp;oid=c8aa93cab5&amp;' \
        'epoch=1738781340&amp;num=2&amp;format=text"'
      )
    end

    it 'does not display binary content' do
      @nodes.expects(:get_version).with('sw5', nil, 'c8aa93cab5').returns("\xff\x42 binary content\x00")

      get '/node/version/view?node=sw5&group=&oid=c8aa93cab5&epoch=1738781340&num=2'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?('cannot display')).must_equal true
    end

    it 'fetches a git-version when using a group containing /' do
      @nodes.expects(:get_version).with('sw5', 'my/group', 'c8aa93cab5').returns('Old configuration of sw5')

      get '/node/version/view?node=sw5&group=my/group&oid=c8aa93cab5&epoch=1738781340&num=2'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?('Old configuration of sw5')).must_equal true
    end

    it 'does not encode html-chars in text-format' do
      configuration = "text &/<> \n ascii;"
      @nodes.expects(:get_version).with('sw5', nil, 'c8aa93cab5').returns(configuration)
      get '/node/version/view?node=sw5&group=&oid=c8aa93cab5&epoch=1738781340&num=2&format=text'

      _(last_response.ok?).must_equal true
      _(last_response.body).must_equal configuration
    end

    it 'does not encode html-chars in json-format' do
      configuration = "text &/<> \n ascii;"
      @nodes.expects(:get_version).with('sw5', nil, 'c8aa93cab5').returns(configuration)
      get '/node/version/view?node=sw5&group=&oid=c8aa93cab5&epoch=1738781340&num=2&format=json'

      _(last_response.ok?).must_equal true
      _(last_response.body).must_equal '["text &/<> \n"," ascii;"]'
    end

    it 'returns 200 when group param is absent (no NoMethodError)' do
      @nodes.expects(:get_version).with('sw5', nil, 'c8aa93cab5').returns('Old configuration of sw5')

      get '/node/version/view?node=sw5&oid=c8aa93cab5&epoch=1738781340&num=2'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?('Old configuration of sw5')).must_equal true
    end
  end

  describe 'get /node/version/diffs' do
    it 'diffs a version with the latest configuration' do
      @versions = [
        { oid: "C006", time: Time.parse("2025-02-05 19:49:00 +0100") },
        { oid: "C003", time: Time.parse("2025-02-05 19:03:00 +0100") },
        { oid: "C001", time: Time.parse("2025-02-05 19:01:00 +0100") }
      ]
      @diff = { patch: "diff --git a/sw5 b/sw5\n" \
                       "index C006..C003 100644\n" \
                       "--- a/sw5\n" \
                       "+++ b/sw5\n" \
                       "@@ -38,12 +38,12 @@ some_line\n " \
                       "unchanged line\n" \
                       "-changed line old\n" \
                       "+changed line new1\n" \
                       "+changed line new2\n " \
                       "\n " \
                       "unchanged line\n",
                stat: [1, 2] }

      @nodes.expects(:version).with('sw5', nil).returns(@versions)
      @nodes.expects(:get_diff).returns(@diff)

      get '/node/version/diffs?node=sw5&group=&oid=C006&epoch=1738781340&num=3'
      _(last_response.ok?).must_equal true
      # The test needs to pass in any timezone, so we use Time.parse to get the
      # right string
      _(last_response.body.include?(
          "Date of version:\n" \
          "<span class=\"time\" epoch=\"1738781340\">" \
          "#{Time.at(1738781340)}</span>"
        )).must_equal true
    end

    it 'renders the old and the new version side by side' do
      versions = [
        { oid: "C006", time: Time.parse("2025-02-05 19:49:00 +0100") },
        { oid: "C003", time: Time.parse("2025-02-05 19:03:00 +0100") }
      ]
      diff = { patch: "@@ -1,2 +1,2 @@\n a & b\n-old <x>\n+new &amp;\n+added\n", stat: [2, 1] }
      @nodes.expects(:version).with('sw5', 'my/group').returns(versions)
      @nodes.expects(:get_diff).with('sw5', 'my/group', 'C006', nil).returns(diff)

      get '/node/version/diffs?node=sw5&group=my/group&oid=C006&epoch=1738781340&num=2'
      _(last_response.ok?).must_equal true
      body = last_response.body
      # .diffs_old and .diffs_new use "white-space: pre", so the whitespace
      # between the lines is visible and must not change. The &nbsp; inserted
      # to align both sides must not be escaped.
      _(body).must_include(
        '<div class="diffs_old">' \
        "<div class=\"diff-index\">@@ -1,2 +1,2 @@\n</div>" \
        "<div> a &amp; b\n</div>" \
        "<div class=\"deleted\">-old &lt;x&gt;\n</div>" \
        "<div>&nbsp;\n</div>" \
        '</div>'
      )
      _(body).must_include(
        '<div class="diffs_new">' \
        "<div class=\"diff-index\">@@ -1,2 +1,2 @@\n</div>" \
        "<div> a &amp; b\n</div>" \
        "<div class=\"added\">+new &amp;amp;\n</div>" \
        "<div class=\"added\">+added\n</div>" \
        '</div>'
      )
      _(body).must_include '<span class="added">added 2</span>'
      _(body).must_include '<span class="deleted">removed 1</span>'
      _(body).must_include '<a href="/node/version?node_full=my/group/sw5">versions</a>'
      _(body).must_include(
        'action="/node/version/diffs?node=sw5&amp;group=my/group&amp;oid=C006&amp;epoch=1738781340&amp;num=2"'
      )
      _(body).must_match(%r{<option value="C006">Version 2 \(.* ago\)</option>\s*<option value="C003">Version 1 \(})
    end

    it 'returns 200 when group param is absent (no NoMethodError)' do
      @versions = [
        { oid: "C006", time: Time.parse("2025-02-05 19:49:00 +0100") },
        { oid: "C003", time: Time.parse("2025-02-05 19:03:00 +0100") }
      ]
      @diff = { patch: "diff --git a/sw5 b/sw5\nsome diff\n", stat: [1, 1] }

      @nodes.expects(:version).with('sw5', nil).returns(@versions)
      @nodes.expects(:get_diff).with('sw5', nil, 'C006', nil).returns(@diff)

      get '/node/version/diffs?node=sw5&oid=C006&epoch=1738781340&num=2'
      _(last_response.ok?).must_equal true
    end

    it 'passes nil group to get_diff for ungrouped nodes' do
      @versions = [
        { oid: "C006", time: Time.parse("2025-02-05 19:49:00 +0100") },
        { oid: "C003", time: Time.parse("2025-02-05 19:03:00 +0100") }
      ]
      @diff = { patch: "diff --git a/sw5 b/sw5\nsome diff\n", stat: [1, 1] }

      # Explicitly assert nil is passed, not '' — empty string would resolve
      # to wrong git path in oxidized's yield_repo_and_path
      @nodes.expects(:version).with('sw5', nil).returns(@versions)
      @nodes.expects(:get_diff).with('sw5', nil, 'C006', nil).returns(@diff)

      get '/node/version/diffs?node=sw5&oid=C006&epoch=1738781340&num=2'
      _(last_response.ok?).must_equal true
    end
  end
end
