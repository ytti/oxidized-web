require_relative '../../spec_helper'

# Test the helper methods of Oxidized::API::Helpers::Url

describe Oxidized::API::WebApp do
  before do
    @webapp = Oxidized::API::WebApp.new
  end

  describe 'url_escape' do
    it 'encodes characters with a special meaning in URLs' do
      # private method => we must use send
      result = @webapp.helpers.send(:url_escape, 'sw#1 &+%?=;"\'<>é')
      _(result).must_equal 'sw%231%20%26%2B%25%3F%3D%3B%22%27%3C%3E%C3%A9'
    end

    it 'keeps "/" and unreserved characters' do
      _(@webapp.helpers.send(:url_escape, 'my/group/sw-1_a.b~c')).must_equal 'my/group/sw-1_a.b~c'
    end

    it 'converts nil to an empty string' do
      _(@webapp.helpers.send(:url_escape, nil)).must_equal ''
    end
  end

  describe 'url_query' do
    it 'builds a query string with encoded values' do
      result = @webapp.helpers.send(:url_query, { node: 'sw#1', group: nil, num: 3 })
      _(result).must_equal 'node=sw%231&group=&num=3'
    end
  end
end
