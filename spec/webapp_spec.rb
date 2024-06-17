require_relative 'spec_helper'

# Test helper methods in Oxidized::API::WebApp

describe Oxidized::API::WebApp do
  include Rack::Test::Methods

  before do
    @webapp = Oxidized::API::WebApp.new
  end

  describe 'convert_to_utf8' do
    it 'cannot work with binary data' do
      # private method => we must use send
      result = @webapp.helpers.send(:convert_to_utf8, "\xff\x42 binary content\x00")
      _(result).must_equal 'The text contains binary values - cannot display'
    end
  end

  describe 'diff_view' do
    it 'cannot work with binary data' do
      # private method => we must use send
      result = @webapp.helpers.send(:diff_view, "\xff\x42 binary content\x00")
      _(result[:old_diff]).must_equal ['The text contains binary values - cannot display']
      _(result[:new_diff]).must_equal ['The text contains binary values - cannot display']
    end
  end
end
