require_relative '../spec_helper'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  before do
    @nodes = mock('Oxidized::Nodes')
    app.set(:nodes, @nodes)
    app.set(:configuration, { hide_node_vars: [], mtime_from_versions: false })
  end

  describe 'layout' do
    it 'renders the head, the view and the footer in one html document' do
      @nodes.expects(:list).returns([])

      get '/nodes'

      _(last_response.ok?).must_equal true
      body = last_response.body
      _(body).must_match(/\A<!DOCTYPE html>\s*<html lang="en">/)
      _(body).must_include '<title>oxidized</title>'
      _(body).must_include 'Oxidized-web v.' \
                           "#{Oxidized::API::WEB_VERSION}, Oxidized v.#{Oxidized::VERSION}"
      _(body).wont_include '&lt;'

      positions = ['<head>', '</head>', '<nav ', 'id="nodesTable"', '<footer ', '</html>'].map do |tag|
        body.index(tag)
      end
      _(positions).wont_include nil
      _(positions).must_equal positions.sort
    end

    it 'prefixes asset and navigation urls with the script name' do
      @nodes.expects(:list).returns([])

      get '/nodes', {}, 'SCRIPT_NAME' => '/oxidized'

      _(last_response.ok?).must_equal true
      body = last_response.body
      _(body).must_include '<script src="/oxidized/weblibs/jquery.js"></script>'
      _(body).must_include 'href="/oxidized/weblibs/bootstrap.css"'
      _(body).must_include 'href="/oxidized/css/oxidized.css"'
      _(body).must_include 'href="/oxidized/images/favicon.ico"'
      _(body).must_include '<script src="/oxidized/scripts/oxidized.js"></script>'
      _(body).must_include 'href="/oxidized/"'
      _(body).must_include 'src="/oxidized/images/oxidizing_40px.png"'
      _(body).must_include 'href="/oxidized/nodes/stats"'
      _(body).must_include 'action="/oxidized/nodes/conf_search"'
    end

    it 'marks the stats menu entry as active on the stats page only' do
      stats_link = %r{<a(?=[^>]*\bhref="/nodes/stats")(?=[^>]*\bclass="nav-link active")[^>]*>Stats</a>}

      @nodes.expects(:list).returns([])
      get '/nodes'
      _(last_response.body).wont_match stats_link

      @nodes.expects(:each)
      get '/nodes/stats'
      _(last_response.body).must_match stats_link
    end
  end
end
