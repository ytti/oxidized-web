require_relative '../spec_helper'

# Node names, groups and models with characters that have a special meaning in
# URLs must be URL-encoded in the links, and arrive unchanged in the routes.
describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  let(:node_name) { 'sw#1 &+%?' }
  let(:group_name) { 'gr p&q' }
  let(:node_url) { 'sw%231%20%26%2B%25%3F' }
  let(:group_url) { 'gr%20p%26q' }

  def app
    Oxidized::API::WebApp
  end

  # href (or action) of the element with the given title, HTML-unescaped
  def link(title)
    tag = last_response.body[/<[^>]*\btitle="#{Regexp.escape(title)}"[^>]*>/m]
    _(tag).wont_be_nil
    CGI.unescapeHTML(tag[/\b(?:href|action)="([^"]*)"/, 1])
  end

  before do
    @nodes = mock('Oxidized::Nodes')
    app.set(:nodes, @nodes)
    app.set(:configuration, { hide_node_vars: [], mtime_from_versions: false })
    @versions = [
      { oid: 'C006', time: Time.parse('2025-02-05 19:49:00 +0100') },
      { oid: 'C003', time: Time.parse('2025-02-05 19:03:00 +0100') }
    ]
  end

  it 'encodes the links in the node list' do
    @nodes.expects(:list).returns(
      [{ name: node_name, model: 'i#os', group: group_name, full_name: "#{group_name}/#{node_name}",
         time: 'never', mtime: 'never' }]
    )

    get '/nodes'

    body = last_response.body
    _(body).must_include "href=\"/node/show/#{node_url}\""
    _(body).must_include 'href="/nodes/model/i%23os"'
    _(body).must_include "href=\"/nodes/group/#{group_url}\""
    _(link('Configuration')).must_equal "/node/fetch/#{group_url}/#{node_url}"
    _(link('Versions')).must_equal "/node/version?node_full=#{group_url}/#{node_url}"
    _(link('Update configuration')).must_equal "/node/next/#{group_url}/#{node_url}"
  end

  it 'decodes the node and group in the path of /node/fetch' do
    @nodes.expects(:fetch).with(node_name, group_name).returns('config')

    get "/node/fetch/#{group_url}/#{node_url}"

    _(last_response.body).must_equal 'config'
  end

  it 'decodes the model in the path of /nodes/model' do
    @nodes.expects(:list).returns([{ name: 'sw1', model: 'i#os' }, { name: 'sw2', model: 'ios' }])

    get '/nodes/model/i%23os.json'

    _(JSON.parse(last_response.body).map { |n| n['name'] }).must_equal ['sw1']
  end

  it 'keeps the node and group from the versions list to the version view' do
    @nodes.expects(:version).with(node_name, group_name).returns(@versions)
    get "/node/version?node_full=#{group_url}/#{node_url}"

    view = link('configuration')
    _(view).must_equal "/node/version/view?node=#{node_url}&group=#{group_url}&oid=C006&epoch=1738781340&num=2"

    @nodes.expects(:get_version).with(node_name, group_name, 'C006').returns('old config')
    get view

    _(last_response.body).must_include 'old config'
    raw = CGI.unescapeHTML(last_response.body[/href="([^"]*)">raw</, 1])
    _(raw).must_include "node=#{node_url}&group=#{group_url}&"
  end

  it 'keeps the node and group from the diffs form through the redirect' do
    @nodes.expects(:version).with(node_name, group_name).returns(@versions)
    @nodes.expects(:get_diff).with(node_name, group_name, 'C006', nil).returns({ patch: "-a\n+b\n", stat: [1, 1] })
    get "/node/version/diffs?node=#{node_url}&group=#{group_url}&oid=C006&epoch=1738781340&num=2"

    action = CGI.unescapeHTML(last_response.body[/<form action="([^"]*)" method="post" role="form">/, 1])
    _(action).must_equal "/node/version/diffs?node=#{node_url}&group=#{group_url}&oid=C006&epoch=1738781340&num=2"
    _(last_response.body).must_include "href=\"/node/version?node_full=#{group_url}/#{node_url}\""

    post action, oid2: 'C003'

    _(last_response.redirect?).must_equal true
    _(last_response.location).must_equal "http://example.org/node/version/diffs?node=#{node_url}&group=#{group_url}" \
                                         '&oid=C006&epoch=1738781340&num=2&oid2=C003'
  end
end
