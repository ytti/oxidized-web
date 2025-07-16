require_relative '../spec_helper'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  before do
    @nodes = mock('Oxidized::Nodes')
    app.set(:nodes, @nodes)
  end

  describe '/node/version.?:format?' do
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
          "<tr>\n<td>3</td>\n<td class='time' epoch='1738781340'>" \
          "2025-02-05 19:49:00 +0100</td>\n"
        )).must_equal true

      _(last_response.body.include?(
          "href='/node/version/view?node=sw5&amp;group=&amp;oid=C006&amp;" \
          "epoch=1738781340&amp;num=3' title='configuration'>"
        )).must_equal true
      _(last_response.body.include?(
          "href='/node/version/diffs?node=sw5&amp;group=&amp;oid=C006&amp;" \
          "epoch=1738781340&amp;num=3' title='diff'>"
        )).must_equal true
    end

    it 'fetches all versions of a node with a group' do
      @nodes.expects(:version).with('sw5', 'group1').returns(@versions)

      get '/node/version?node_full=group1/sw5'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?(
          "<tr>\n<td>3</td>\n<td class='time' epoch='1738781340'>" \
          "2025-02-05 19:49:00 +0100</td>\n"
        )).must_equal true
    end

    it 'fetches all versions of a node with a group with /' do
      @nodes.expects(:version).with('sw5', 'gr/oup1').returns(@versions)

      get '/node/version?node_full=gr/oup1/sw5'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?(
          "<tr>\n<td>3</td>\n<td class='time' epoch='1738781340'>" \
          "2025-02-05 19:49:00 +0100</td>\n"
        )).must_equal true
    end
  end

  describe '/node/version/view.?:format?' do
    it 'fetches a previous version from git' do
      @nodes.expects(:get_version).with('sw5', '', 'c8aa93cab5').returns('Old configuration of sw5')

      get '/node/version/view?node=sw5&group=&oid=c8aa93cab5&epoch=1738781340&num=2'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?('Old configuration of sw5')).must_equal true
      # The test needs to pass in any timezone, so we use Time.parse to get the
      # right string
      _(last_response.body.include?(
          "Date of version:\n" \
          "<span class='time' epoch='1738781340'>" \
          "#{Time.at(1738781340)}</span>" # rubocop:disable Style/NumericLiterals
        )).must_equal true
    end

    it 'does not display binary content' do
      @nodes.expects(:get_version).with('sw5', '', 'c8aa93cab5').returns("\xff\x42 binary content\x00")

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
      @nodes.expects(:get_version).with('sw5', '', 'c8aa93cab5').returns(configuration)
      get '/node/version/view?node=sw5&group=&oid=c8aa93cab5&epoch=1738781340&num=2&format=text'

      _(last_response.ok?).must_equal true
      _(last_response.body).must_equal configuration
    end

    it 'does not encode html-chars in json-format' do
      configuration = "text &/<> \n ascii;"
      @nodes.expects(:get_version).with('sw5', '', 'c8aa93cab5').returns(configuration)
      get '/node/version/view?node=sw5&group=&oid=c8aa93cab5&epoch=1738781340&num=2&format=json'

      _(last_response.ok?).must_equal true
      _(last_response.body).must_equal '["text &/<> \n"," ascii;"]'
    end
  end

  describe '/node/version/diffs' do
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
          "<span class='time' epoch='1738781340'>" \
          "#{Time.at(1738781340)}</span>" # rubocop:disable Style/NumericLiterals
        )).must_equal true
    end
  end
end
