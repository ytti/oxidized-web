require_relative '../../spec_helper'
describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  before do
    @nodes = mock('Oxidized::Nodes')
    app.set(:nodes, @nodes)

    @serialized_node = {
      name: "sw5",
      full_name: "sw5.example.com",
      ip: "10.42.12.42",
      group: nil,
      model: "ios",
      last: {
        start: Time.parse("2025-02-05 19:49:00 +0100"),
        end: Time.parse("2025-02-05 19:49:10 +0100"),
        status: :no_connection,
        time: 10
      },
      vars: {
        oxi: "dized",
        enable: "secret_enable",
        username: "oxidized",
        password: "secret_password"
      },
      mtime: Time.parse("2025-02-05 19:49:11 +0100")
    }
  end

  describe "get /node/show/:node" do
    it "shows the metadata of a node" do
      app.set(:configuration, { hide_node_vars: [] })
      @nodes.expects(:show).with("sw5").returns(@serialized_node)

      get '/node/show/sw5'
      _(last_response.ok?).must_equal true
      body = last_response.body

      _(body).must_match(/secret_enable/)
      _(body).must_match(/secret_password/)
      _(body.include?(
          "<code>{\n  &quot;name&quot;: &quot;sw5&quot;," \
          "\n  &quot;full_name&quot;: &quot;sw5.example.com&quot;," \
          "\n  &quot;ip&quot;: &quot;10.42.12.42&quot;," \
          "\n  &quot;group&quot;: null,\n  &quot;model&quot;: &quot;ios&quot;," \
          "\n  &quot;last&quot;: {" \
          "\n    &quot;start&quot;: &quot;2025-02-05 19:49:00 +0100&quot;," \
          "\n    &quot;end&quot;: &quot;2025-02-05 19:49:10 +0100&quot;," \
          "\n    &quot;status&quot;: &quot;no_connection&quot;," \
          "\n    &quot;time&quot;: 10\n  }," \
          "\n  &quot;vars&quot;: {" \
          "\n    &quot;oxi&quot;: &quot;dized&quot;," \
          "\n    &quot;enable&quot;: &quot;secret_enable&quot;," \
          "\n    &quot;username&quot;: &quot;oxidized&quot;," \
          "\n    &quot;password&quot;: &quot;secret_password&quot;" \
          "\n  },\n  &quot;mtime&quot;: &quot;2025-02-05 19:49:11 +0100&quot;" \
          "\n}</code>"
        )).must_equal true
    end

    it "hides vars in hide_node_vars" do
      app.set(:configuration, { hide_node_vars: %i[enable password] })
      @nodes.expects(:show).with("sw5").returns(@serialized_node)

      get '/node/show/sw5'
      _(last_response.ok?).must_equal true
      body = last_response.body

      _(body).wont_match(/secret_enable/)
      _(body).wont_match(/secret_password/)
      _(body).must_match(/&lt;hidden&gt;/)
      _(body.include?(
          "<code>{\n  &quot;name&quot;: &quot;sw5&quot;," \
          "\n  &quot;full_name&quot;: &quot;sw5.example.com&quot;," \
          "\n  &quot;ip&quot;: &quot;10.42.12.42&quot;," \
          "\n  &quot;group&quot;: null,\n  &quot;model&quot;: &quot;ios&quot;," \
          "\n  &quot;last&quot;: {" \
          "\n    &quot;start&quot;: &quot;2025-02-05 19:49:00 +0100&quot;," \
          "\n    &quot;end&quot;: &quot;2025-02-05 19:49:10 +0100&quot;," \
          "\n    &quot;status&quot;: &quot;no_connection&quot;," \
          "\n    &quot;time&quot;: 10\n  }," \
          "\n  &quot;vars&quot;: {" \
          "\n    &quot;oxi&quot;: &quot;dized&quot;," \
          "\n    &quot;enable&quot;: &quot;&lt;hidden&gt;&quot;," \
          "\n    &quot;username&quot;: &quot;oxidized&quot;," \
          "\n    &quot;password&quot;: &quot;&lt;hidden&gt;&quot;" \
          "\n  },\n  &quot;mtime&quot;: &quot;2025-02-05 19:49:11 +0100&quot;" \
          "\n}</code>"
        )).must_equal true

      # The note data is not changed (deep copy with Marshal)
      _(@serialized_node[:vars][:enable]).must_equal "secret_enable"
    end
  end
end
