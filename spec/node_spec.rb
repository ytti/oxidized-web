require_relative 'spec_helper'

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  def app
    Oxidized::API::WebApp
  end

  describe '/node/fetch/:node' do
    it 'Gets the latest version of a node' do
      nodes = mock('object')
      nodes.expects(:fetch).returns('Configuration of sw42')
      app.set(:nodes, nodes)

      get '/node/fetch/sw42'
      _(last_response.ok?).must_equal true
      _(last_response.body).must_equal 'Configuration of sw42'
    end
  end

  describe '/node/version/view.?:format?' do
    it 'Fetches an old version from git' do
      nodes = mock('object')
      nodes.expects(:get_version).returns('Old configuration of sw42')
      app.set(:nodes, nodes)

      get '/node/version/view?node=sw5&group=&oid=c8aa93cab5&date=2024-06-07 08:27:37 +0200&num=2'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?('Old configuration of sw42')).must_equal true
    end

    it 'Does not display binary content' do
      nodes = mock('object')
      nodes.expects(:get_version).returns("\xff\x42 binary content\x00")
      app.set(:nodes, nodes)

      get '/node/version/view?node=sw5&group=&oid=c8aa93cab5&date=2024-06-07 08:27:37 +0200&num=2'
      _(last_response.ok?).must_equal true
      _(last_response.body.include?('cannot display')).must_equal true
    end
  end
end
