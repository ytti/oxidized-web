require_relative 'spec_helper'

describe Oxidized::API::Web do
  describe "#parse_legacy_configuration" do
    test_cases = [
      {
        configuration: "192.168.1.100:9999",
        expected: ["192.168.1.100", 9999, "", []],
        description: "IP address and port"
      },
      {
        configuration: "[::1]:8080",
        expected: ["[::1]", 8080, "", []],
        description: "IPv6 address with port"
      },
      {
        configuration: "1234",
        expected: ["", 1234, "", []],
        description: "port only"
      },
      {
        configuration: "0.0.0.0:9999/api",
        expected: ["0.0.0.0", 9999, "api", []],
        description: "host:port/prefix"
      },
      {
        configuration: "8888/v1",
        expected: ["", 8888, "v1", []],
        description: "port/prefix"
      },
      {
        configuration: "127.0.0.1:3000/api/v2",
        expected: ["127.0.0.1", 3000, "api/v2", []],
        description: "complex URI prefix"
      },
      {
        configuration: "127.0.0.1:3000/",
        expected: ["127.0.0.1", 3000, "", []],
        description: "empty URI prefix after slash"
      }
    ]

    test_cases.each do |test_case|
      it "should parse #{test_case[:description]} correctly" do
        result = Oxidized::API::Web.parse_legacy_configuration(test_case[:configuration])
        expect(result).must_equal test_case[:expected]
      end
    end
  end

  describe "#parse_new_configuration" do
    test_cases = [
      {
        configuration: Asetus::ConfigStruct.new(
          {
            'listen' => '0.0.0.0',
            'port' => 3000,
            'url_prefix' => '/api',
            'vhosts' => ['example.com', 'test.com']
          }
        ),
        expected: ['0.0.0.0', 3000, '/api', ['example.com', 'test.com']],
        description: "all values provided"
      },
      {
        configuration: Asetus::ConfigStruct.new,
        expected: ['127.0.0.1', 8888, '', []],
        description: "all default values"
      }
    ]

    test_cases.each do |test_case|
      it "should parse #{test_case[:description]} correctly" do
        result = Oxidized::API::Web.parse_configuration(test_case[:configuration])
        expect(result).must_equal test_case[:expected]
      end
    end
  end
end
