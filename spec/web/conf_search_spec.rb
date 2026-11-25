require_relative '../spec_helper'
require 'json'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  before do
    @nodes = mock('Oxidized::Nodes')
    app.set(:nodes, @nodes)
  end

  describe 'post /nodes/conf_search' do
    # @nodes has no expectations, so any config lookup would fail these tests
    it 'shows the search page without results when search_in_conf_textbox is missing' do
      post '/nodes/conf_search'
      _(last_response.ok?).must_equal true
      _(last_response.body).must_include 'Config search'
      _(last_response.body).must_include 'name="search_in_conf_textbox"'
      _(last_response.body).wont_include 'versionsTable'
    end

    it 'shows the search page without results when search_in_conf_textbox is blank' do
      post '/nodes/conf_search', search_in_conf_textbox: ''
      _(last_response.ok?).must_equal true
      _(last_response.body).must_include 'Config search'
      _(last_response.body).wont_include 'Nodes that contain'
    end

    it 'returns an empty json list when search_in_conf_textbox is blank' do
      post '/nodes/conf_search.json', search_in_conf_textbox: ''
      _(last_response.ok?).must_equal true
      _(JSON.parse(last_response.body)).must_equal []
    end

    it 'returns 400 with an error when regex is malformed (no crash)' do
      post '/nodes/conf_search.json', search_in_conf_textbox: '['
      _(last_response.status).must_equal 400
      _(JSON.parse(last_response.body)['error']).must_match(/Invalid regular expression/)
    end

    it 'shows the error when regex is malformed in the html view' do
      post '/nodes/conf_search', search_in_conf_textbox: '['
      _(last_response.status).must_equal 400
      _(last_response.body).must_include 'Invalid regular expression'
    end

    it 'returns 200 with matches when regex is valid' do
      @nodes.expects(:list).returns(
        [{ name: 'sw5', full_name: 'sw5', group: nil }]
      )
      @nodes.expects(:fetch).with('sw5', nil).returns("hostname sw5\n")
      post '/nodes/conf_search', search_in_conf_textbox: 'hostname'
      _(last_response.ok?).must_equal true
    end

    it 'does not match binary configs' do
      @nodes.expects(:list).returns(
        [{ name: 'bin', full_name: 'bin', group: nil },
         { name: 'txt', full_name: 'txt', group: nil }]
      )
      @nodes.expects(:fetch).with('bin', nil).returns("\xff\x42 binary content\x00".b)
      @nodes.expects(:fetch).with('txt', nil).returns("description binary\n".b)
      # must not match the placeholder 'The text contains binary values...'
      post '/nodes/conf_search.json', search_in_conf_textbox: 'binary'
      _(last_response.ok?).must_equal true
      _(JSON.parse(last_response.body).map { |r| r.slice('node', 'full_name') }).must_equal [
        { 'node' => 'txt', 'full_name' => 'txt' }
      ]
    end

    it 'skips nodes without config' do
      @nodes.expects(:list).returns(
        [{ name: 'none', full_name: 'none', group: nil },
         { name: 'sw5', full_name: 'sw5', group: nil }]
      )
      # output file returns nil when the config file does not exist
      @nodes.expects(:fetch).with('none', nil).returns(nil)
      @nodes.expects(:fetch).with('sw5', nil).returns("hostname sw5\n")
      post '/nodes/conf_search.json', search_in_conf_textbox: 'hostname'
      _(last_response.ok?).must_equal true
      _(JSON.parse(last_response.body).map { |r| r.slice('node', 'full_name') }).must_equal [
        { 'node' => 'sw5', 'full_name' => 'sw5' }
      ]
    end

    describe 'with non-ASCII characters' do
      # Output modules (e.g. git/rugged) return the config as ASCII-8BIT
      before do
        @nodes.expects(:list).returns(
          [{ name: 'utf8', full_name: 'utf8', group: nil },
           { name: 'latin1', full_name: 'latin1', group: nil },
           { name: 'ascii', full_name: 'ascii', group: nil }]
        )
        @nodes.expects(:fetch).with('utf8', nil)
              .returns("hostname utf8\ndescription Bod\xC3\xB8 \xC3\xA5\n".b)
        @nodes.expects(:fetch).with('latin1', nil)
              .returns("hostname latin1\ndescription Bod\xF8 \xE5\n".b)
        @nodes.expects(:fetch).with('ascii', nil)
              .returns("hostname ascii\ndescription Bodo a\n".b)
      end

      it 'finds UTF-8 and Latin1 encoded configs' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'Bodø å'
        _(last_response.ok?).must_equal true
        _(JSON.parse(last_response.body).map { |r| r.slice('node', 'full_name') }).must_equal [
          { 'node' => 'utf8', 'full_name' => 'utf8' },
          { 'node' => 'latin1', 'full_name' => 'latin1' }
        ]
      end

      it 'still finds ASCII search terms in all configs' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'description'
        _(last_response.ok?).must_equal true
        _(JSON.parse(last_response.body).map { |r| r.slice('node', 'full_name') }).must_equal [
          { 'node' => 'utf8', 'full_name' => 'utf8' },
          { 'node' => 'latin1', 'full_name' => 'latin1' },
          { 'node' => 'ascii', 'full_name' => 'ascii' }
        ]
      end
    end

    describe 'with matching snippets' do
      before do
        @nodes.stubs(:list).returns(
          [{ name: 'sw4', full_name: 'sw4', group: nil },
           { name: 'sw5', full_name: 'sw5', group: nil }]
        )
        config = [
          'interface ge-0/0/0',
          '  description uplink to core',
          '  mtu 9000',
          'interface ge-0/0/1',
          '  description access port',
          'system {',
          '  host-name sw4',
          '}',
          'routing-options {',
          '  autonomous-system 64512;',
          '  router-id 192.0.2.1;',
          '}',
          'policy-options {',
          '  description primary policy',
          '  description secondary policy',
          '}'
        ].join("\n")
        @nodes.stubs(:fetch).returns('no match here')
        @nodes.stubs(:fetch).with('sw4', nil).returns(config)
      end

      it 'lists only nodes whose configuration matches' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'description'

        _(last_response.ok?).must_equal true
        result = JSON.parse(last_response.body)
        _(result.length).must_equal 1
        _(result[0]['node']).must_equal 'sw4'
      end

      it 'merges overlapping context into one snippet' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'description',
                                        search_max_matches: '0'

        matches = JSON.parse(last_response.body)[0]['matches']
        _(matches.length).must_equal 2

        first = matches[0]
        _(first['line_number']).must_equal 2
        _(first['line_numbers']).must_equal [2, 5]
        _(first['snippet'].map { |l| l['number'] }).must_equal [1, 2, 3, 4, 5, 6, 7]
        _(first['snippet'][1]['match']).must_equal true
        _(first['snippet'][1]['text']).must_equal '  description uplink to core'
        _(first['snippet'][0]['match']).must_equal false
        _(first['snippet'][4]['match']).must_equal true

        second = matches[1]
        _(second['line_number']).must_equal 14
        _(second['line_numbers']).must_equal [14, 15]
        _(second['snippet'].map { |l| l['number'] }).must_equal [12, 13, 14, 15, 16]
        _(second['snippet'].select { |l| l['match'] }.map { |l| l['number'] }).must_equal [14, 15]
      end

      it 'merges context windows that touch without overlapping' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'uplink|host-name'

        matches = JSON.parse(last_response.body)[0]['matches']
        _(matches.length).must_equal 1
        _(matches[0]['line_numbers']).must_equal [2, 7]
        _(matches[0]['snippet'].map { |l| l['number'] }).must_equal (1..9).to_a
      end

      it 'matches a regular expression that spans lines' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'uplink[\s\S]*host-name'

        result = JSON.parse(last_response.body)
        _(result.length).must_equal 1
        matches = result[0]['matches']
        _(matches.length).must_equal 1
        _(matches[0]['line_number']).must_equal 2
        _(matches[0]['line_numbers']).must_equal (2..7).to_a
        _(matches[0]['snippet'].map { |l| l['number'] }).must_equal (1..9).to_a

        snippet = matches[0]['snippet'].to_h { |l| [l['number'], l['highlights']] }
        _(snippet[1]).must_equal []
        _(snippet[2]).must_equal [[14, 28]]
        _(snippet[3]).must_equal [[0, 10]]
        _(snippet[7]).must_equal [[0, 11]]
        _(snippet[8]).must_equal []
      end

      it 'matches a newline in the search term' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'core\n  mtu'

        matches = JSON.parse(last_response.body)[0]['matches']
        _(matches.length).must_equal 1
        _(matches[0]['line_numbers']).must_equal [2, 3]
      end

      it 'matches \R as a line break' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'core\R'

        matches = JSON.parse(last_response.body)[0]['matches']
        _(matches[0]['line_numbers']).must_equal [2]
        _(matches[0]['snippet'][1]['highlights']).must_equal [[24, 28]]
      end

      it 'anchors \A to the start of the config, not each line' do
        post '/nodes/conf_search.json', search_in_conf_textbox: '\Ainterface'

        matches = JSON.parse(last_response.body)[0]['matches']
        _(matches.length).must_equal 1
        _(matches[0]['line_numbers']).must_equal [1]
      end

      it 'highlights each line of a multi-line match in the html view' do
        post '/nodes/conf_search', search_in_conf_textbox: 'core\n  mtu'

        _(last_response.ok?).must_equal true
        _(last_response.body).must_include '2:   description uplink to <mark>core</mark>'
        _(last_response.body).must_include '3: <mark>  mtu</mark> 9000'
      end

      it 'highlights the matched text in the html view' do
        post '/nodes/conf_search', search_in_conf_textbox: 'description'

        _(last_response.ok?).must_equal true
        _(last_response.body).must_include '<mark>description</mark>'
      end

      it 'html-escapes the config in the snippets' do
        @nodes.stubs(:fetch).with('sw5', nil)
              .returns("banner <script>alert(1)</script>\nsnmp community a&amp;b\n")
        post '/nodes/conf_search', search_in_conf_textbox: 'script|community'

        _(last_response.ok?).must_equal true
        _(last_response.body).wont_include '<script>alert(1)'
        _(last_response.body).must_include '&lt;<mark>script</mark>&gt;alert(1)'
        _(last_response.body).must_include '<mark>community</mark> a&amp;amp;b'
      end

      it 'treats the search term as a regular expression by default' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'ge-0/0/.'

        result = JSON.parse(last_response.body)
        _(result.length).must_equal 1
        _(result[0]['matches'].length).must_equal 1
        _(result[0]['matches'][0]['line_number']).must_equal 1
        _(result[0]['matches'][0]['line_numbers']).must_equal [1, 4]
      end

      it 'treats the search term as literal text when regex is unticked' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'ge-0/0/.',
                                        search_regex_checkbox: 'off'

        result = JSON.parse(last_response.body)
        _(result.length).must_equal 0
      end

      it 'treats the search term as case-sensitive by default' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'DESCRIPTION'

        result = JSON.parse(last_response.body)
        _(result.length).must_equal 0
      end

      it 'matches case-insensitively when case sensitivity is unticked' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'DESCRIPTION',
                                        search_case_sensitive_checkbox: 'off', search_max_matches: '0'

        result = JSON.parse(last_response.body)
        _(result.length).must_equal 1
        _(result[0]['matches'].map { |m| m['line_numbers'] }).must_equal [[2, 5], [14, 15]]
      end

      it 'combines regular expression and case-insensitive search' do
        post '/nodes/conf_search.json', search_in_conf_textbox: 'DESC.IPTION',
                                        search_case_sensitive_checkbox: 'off', search_max_matches: '0'

        result = JSON.parse(last_response.body)
        _(result.length).must_equal 1
        _(result[0]['matches'].map { |m| m['line_numbers'] }).must_equal [[2, 5], [14, 15]]
      end

      it 'pre-fills the search form with the term and checkbox state' do
        post '/nodes/conf_search', search_in_conf_textbox: 'description'

        _(last_response.ok?).must_equal true
        _(last_response.body).must_include 'value="description"'
        _(last_response.body).must_include 'name="search_regex_checkbox"'
        _(last_response.body).must_include 'name="search_case_sensitive_checkbox"'
        _(last_response.body).must_match(/<input(?=[^>]*\bid="conf-search-regex")(?=[^>]*\bchecked)[^>]*>/)
        _(last_response.body).must_match(/<input(?=[^>]*\bid="conf-search-case-sensitive")(?=[^>]*\bchecked)[^>]*>/)
      end

      it 'keeps the regex checkbox unticked after a literal search' do
        post '/nodes/conf_search', search_in_conf_textbox: 'description',
                                   search_regex_checkbox: 'off'

        _(last_response.ok?).must_equal true
        _(last_response.body).wont_match(/<input(?=[^>]*\bid="conf-search-regex")(?=[^>]*\bchecked)[^>]*>/)
      end

      it 'keeps the case-sensitive checkbox unticked after an insensitive search' do
        post '/nodes/conf_search', search_in_conf_textbox: 'description',
                                   search_case_sensitive_checkbox: 'off'

        _(last_response.ok?).must_equal true
        _(last_response.body).wont_match(/<input(?=[^>]*\bid="conf-search-case-sensitive")(?=[^>]*\bchecked)[^>]*>/)
      end

      it 'uses the checkbox value when a browser sends the hidden field and the checkbox' do
        header 'Content-Type', 'application/x-www-form-urlencoded'
        post '/nodes/conf_search.json',
             'search_in_conf_textbox=ge-0/0/.&search_regex_checkbox=off&search_regex_checkbox=on'

        result = JSON.parse(last_response.body)
        _(result.length).must_equal 1
        _(result[0]['matches'][0]['line_numbers']).must_equal [1, 4]
      end
    end

    describe 'with more snippets than the per-node limit' do
      before do
        @nodes.stubs(:list).returns(
          [{ name: 'sw4', full_name: 'sw4', group: nil },
           { name: 'sw5', full_name: 'core/sw5', group: 'core' }]
        )
        # 8 matches, each far enough apart to give its own snippet
        config = (1..8).flat_map { |i| ["vlan #{i}", 'x', 'x', 'x', 'x', 'x'] }.join("\n")
        @nodes.stubs(:fetch).with('sw4', nil).returns(config)
        @nodes.stubs(:fetch).with('sw5', 'core').returns(config)
      end

      def search(**extra)
        post '/nodes/conf_search.json', search_in_conf_textbox: 'vlan', **extra
        JSON.parse(last_response.body)
      end

      it 'returns 1 snippet per node by default with the total count' do
        result = search
        _(result.length).must_equal 2
        _(result[0]['match_count']).must_equal 8
        _(result[0]['matches'].map { |m| m['line_number'] }).must_equal [1]
      end

      it 'returns the requested number of snippets' do
        result = search(search_max_matches: '2')[0]
        _(result['match_count']).must_equal 8
        _(result['matches'].length).must_equal 2
      end

      it 'returns all snippets when the limit is 0' do
        _(search(search_max_matches: '0')[0]['matches'].length).must_equal 8
      end

      it 'falls back to the default limit on an invalid value' do
        _(search(search_max_matches: 'abc')[0]['matches'].length).must_equal 1
        _(search(search_max_matches: '-1')[0]['matches'].length).must_equal 1
      end

      it 'searches only the given node and returns all its snippets' do
        result = search(search_node: 'core/sw5', search_max_matches: '5')
        _(result.length).must_equal 1
        _(result[0]['full_name']).must_equal 'core/sw5'
        _(result[0]['match_count']).must_equal 8
        _(result[0]['matches'].length).must_equal 8
      end

      it 'returns no results for an unknown node' do
        _(search(search_node: 'nope')).must_equal []
      end

      it 'shows how many snippets are hidden and links to the node search in the html view' do
        post '/nodes/conf_search', search_in_conf_textbox: 'vlan'

        body = last_response.body
        _(last_response.ok?).must_equal true
        _(body.scan('<mark>vlan</mark>').length).must_equal 2
        _(body).must_include '… 7 more snippets'
        _(body).must_include 'show all 8 in sw4'
        _(body).must_match(%r{<input(?=[^>]*\bname="search_node")(?=[^>]*\bvalue="core/sw5")[^>]*>})
        _(body).must_match(/<option(?=[^>]*\bvalue="1")(?=[^>]*\bselected)[^>]*>1</)
      end

      it 'shows all snippets of one node with a way back in the html view' do
        post '/nodes/conf_search', search_in_conf_textbox: 'vlan', search_node: 'sw4',
                                   search_max_matches: '5'

        body = last_response.body
        _(last_response.ok?).must_equal true
        _(body.scan('<mark>vlan</mark>').length).must_equal 8
        _(body).must_match(%r{Matches for\s*<b>\s*vlan\s*</b>\s*in\s*<b>\s*sw4\s*</b>})
        _(body).must_include 'Back to all nodes'
        _(body).wont_include 'more snippets'
        # the selected limit is kept for the way back to all nodes
        _(body).must_match(/<input(?=[^>]*\bname="search_max_matches")(?=[^>]*\btype="hidden")(?=[^>]*\bvalue="5")[^>]*>/)
        _(body).must_match(/<option(?=[^>]*\bvalue="5")(?=[^>]*\bselected)[^>]*>5</)
      end

      it 'does not offer to show more when all snippets are shown' do
        post '/nodes/conf_search', search_in_conf_textbox: 'vlan', search_max_matches: '0'

        _(last_response.body.scan('<mark>vlan</mark>').length).must_equal 16
        _(last_response.body).wont_include 'more snippets'
        _(last_response.body).must_match(/<option(?=[^>]*\bvalue="0")(?=[^>]*\bselected)[^>]*>all</)
      end

      it 'adds a requested limit outside the predefined options to the select' do
        post '/nodes/conf_search', search_in_conf_textbox: 'vlan', search_max_matches: '7'

        _(last_response.body).must_include "… 1 more snippet\n"
        _(last_response.body).must_match(/<option(?=[^>]*\bvalue="7")(?=[^>]*\bselected)[^>]*>7</)
      end
    end
  end
end
