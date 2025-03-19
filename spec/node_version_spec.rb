require_relative 'spec_helper'

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
    it 'fetches all versions of a node without a group' do
      @nodes.expects(:version).with('sw5', nil).returns(
        [{ oid: "C006", date: "2025-02-05 19:49:00 +0100",
           time: Time.parse("2025-02-05 19:49:00 +0100") },
         { oid: "C003", date: "2025-02-05 19:03:00 +0100",
           time: Time.parse("2025-02-05 19:03:00 +0100") },
         { oid: "C001", date: "2025-02-05 19:01:00 +0100",
           time: Time.parse("2025-02-05 19:01:00 +0100") }]
      )

      get '/node/version?node_full=sw5'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?(
          "<tr>\n<td>3</td>\n<td class='time' epoch='1738781340'>" \
          "2025-02-05 19:49:00 +0100</td>\n"
        )).must_equal true
    end

    it 'fetches all versions of a node with a group' do
      @nodes.expects(:version).with('sw5', 'group1').returns(
        [{ oid: "C006", date: "2025-02-05 19:49:00 +0100",
           time: Time.parse("2025-02-05 19:49:00 +0100") },
         { oid: "C003", date: "2025-02-05 19:03:00 +0100",
           time: Time.parse("2025-02-05 19:03:00 +0100") },
         { oid: "C001", date: "2025-02-05 19:01:00 +0100",
           time: Time.parse("2025-02-05 19:01:00 +0100") }]
      )

      get '/node/version?node_full=group1/sw5'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?(
          "<tr>\n<td>3</td>\n<td class='time' epoch='1738781340'>" \
          "2025-02-05 19:49:00 +0100</td>\n"
        )).must_equal true
    end

    it 'fetches all versions of a node with a group with /' do
      @nodes.expects(:version).with('sw5', 'gr/oup1').returns(
        [{ oid: "C006", date: "2025-02-05 19:49:00 +0100",
           time: Time.parse("2025-02-05 19:49:00 +0100") },
         { oid: "C003", date: "2025-02-05 19:03:00 +0100",
           time: Time.parse("2025-02-05 19:03:00 +0100") },
         { oid: "C001", date: "2025-02-05 19:01:00 +0100",
           time: Time.parse("2025-02-05 19:01:00 +0100") }]
      )

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

      get '/node/version/view?node=sw5&group=&oid=c8aa93cab5&date=2024-06-07 08:27:37 +0200&num=2'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?('Old configuration of sw5')).must_equal true
    end

    it 'does not display binary content' do
      @nodes.expects(:get_version).with('sw5', '', 'c8aa93cab5').returns("\xff\x42 binary content\x00")

      get '/node/version/view?node=sw5&group=&oid=c8aa93cab5&date=2024-06-07 08:27:37 +0200&num=2'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?('cannot display')).must_equal true
    end

    it 'fetches a git-version when using a group containing /' do
      @nodes.expects(:get_version).with('sw5', 'my/group', 'c8aa93cab5').returns('Old configuration of sw5')

      get '/node/version/view?node=sw5&group=my/group&oid=c8aa93cab5&date=2024-06-07 08:27:37 +0200&num=2'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?('Old configuration of sw5')).must_equal true
    end

    it 'does not encode html-chars in text-format' do
      configuration = "text &/<> \n ascii;"
      @nodes.expects(:get_version).with('sw5', '', 'c8aa93cab5').returns(configuration)
      get '/node/version/view?node=sw5&group=&oid=c8aa93cab5&date=2024-06-07 08:27:37 +0200&num=2&format=text'

      _(last_response.ok?).must_equal true
      _(last_response.body).must_equal configuration
    end

    it 'does not encode html-chars in json-format' do
      configuration = "text &/<> \n ascii;"
      @nodes.expects(:get_version).with('sw5', '', 'c8aa93cab5').returns(configuration)
      get '/node/version/view?node=sw5&group=&oid=c8aa93cab5&date=2024-06-07 08:27:37 +0200&num=2&format=json'

      _(last_response.ok?).must_equal true
      _(last_response.body).must_equal '["text &/<> \n"," ascii;"]'
    end
  end
end
