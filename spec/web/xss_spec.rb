require_relative '../spec_helper'
require 'cgi'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  before do
    @nodes = mock('Oxidized::Nodes')
    app.set(:nodes, @nodes)
  end

  describe 'reflected XSS prevention' do
    it 'escapes node name in /node/version versions list' do
      # Use a payload without '/' so the routing does not split on rpartition('/')
      malicious = '<img src=x onerror=alert(1)>'
      @nodes.expects(:version).with(malicious, nil).returns([])

      get "/node/version?node_full=#{CGI.escape(malicious)}"

      _(last_response.ok?).must_equal true
      _(last_response.body).must_include('&lt;img src=x onerror=alert(1)&gt;')
      _(last_response.body).wont_include('<img src=x onerror=alert(1)>')
    end

    it 'escapes node name in /node/version/view' do
      malicious = '<script>alert(1)</script>'
      @nodes.expects(:get_version).with(malicious, '', 'abc123').returns('device config')

      get "/node/version/view?node=#{CGI.escape(malicious)}&group=&oid=abc123&epoch=0&num=1"

      _(last_response.ok?).must_equal true
      _(last_response.body).must_include('&lt;script&gt;alert(1)&lt;/script&gt;')
      _(last_response.body).wont_include('<script>alert(1)</script>')
    end

    it 'escapes node name in /node/version/diffs' do
      malicious = '<script>alert(1)</script>'
      versions = [{ oid: 'C006', time: Time.parse('2025-02-05 19:49:00 +0100') }]
      @nodes.expects(:version).with(malicious, nil).returns(versions)
      @nodes.expects(:get_diff).with(malicious, '', 'C006', nil).returns(
        { patch: "- old line\n+ new line\n", stat: [1, 1] }
      )

      get "/node/version/diffs?node=#{CGI.escape(malicious)}&group=&oid=C006&epoch=0&num=1"

      _(last_response.ok?).must_equal true
      _(last_response.body).must_include('&lt;script&gt;alert(1)&lt;/script&gt;')
      _(last_response.body).wont_include('<script>alert(1)</script>')
    end
  end

  describe 'stored XSS prevention' do
    it 'escapes node names in /nodes list' do
      malicious = '<script>alert(1)</script>'
      @nodes.expects(:list).returns(
        [{ name: malicious, ip: '10.0.0.1', model: 'ios',
           full_name: malicious, group: 'default', time: Time.now, mtime: Time.now }]
      )

      get '/nodes'

      _(last_response.ok?).must_equal true
      _(last_response.body).must_include('&lt;script&gt;alert(1)&lt;/script&gt;')
      _(last_response.body).wont_include('<script>alert(1)</script>')
    end
  end
end
