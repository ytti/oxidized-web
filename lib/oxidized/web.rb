# frozen_string_literal: true

require 'json'
require 'puma'

module Oxidized
  module API
    class Web
      include SemanticLogger::Loggable

      attr_reader :thread

      DEFAULT_HOST = '127.0.0.1'
      DEFAULT_PORT = 8888
      DEFAULT_URI_PREFIX = ''

      def initialize(nodes, configuration)
        require 'oxidized/web/webapp'
        @configuration = self.class.parse_configuration(configuration)
        WebApp.set :nodes, nodes
        WebApp.set :configuration, @configuration
        WebApp.set :host_authorization, {
          permitted_hosts: @configuration[:vhosts]
        }
        uri_prefix = @configuration[:uri_prefix]
        @app = Rack::Builder.new do
          map uri_prefix do
            run WebApp
          end
        end
      end

      def run
        @thread = Thread.new do
          @server = Puma::Server.new @app
          addr = @configuration[:addr]
          port = @configuration[:port]
          @server.add_tcp_listener addr, port
          logger.info "Oxidized-web server listening on #{addr}:#{port}"
          @server.run.join
        end
      end

      def self.parse_configuration(configuration)
        if configuration.instance_of? Asetus::ConfigStruct
          parse_new_configuration(configuration)
        else
          parse_legacy_configuration(configuration)
        end
      end

      # New configuration style: extensions.oxidized-web
      def self.parse_new_configuration(configuration)
        hide_node_vars = configuration.hide_node_vars? || []
        unless hide_node_vars.is_a?(Array)
          logger.error "hide_node_vars must be a list of strings"
          hide_node_vars = []
        end
        hide_node_vars = hide_node_vars.map(&:to_sym)
        {
          addr: configuration.listen? || DEFAULT_HOST,
          port: configuration.port? || DEFAULT_PORT,
          uri_prefix: normalize_uri(configuration.url_prefix? ||
                                    DEFAULT_URI_PREFIX),
          vhosts: configuration.vhosts? || [],
          hide_node_vars: hide_node_vars
        }
      end

      # Legacy configuration style: "rest: 127.0.0.1:8888/prefix"
      def self.parse_legacy_configuration(configuration)
        listen, uri_prefix = configuration.split('/', 2)
        addr, _, port = listen.rpartition ':'
        unless port
          port = addr
          addr = nil
        end
        {
          addr: addr,
          port: port.to_i,
          uri_prefix: normalize_uri(uri_prefix || DEFAULT_URI_PREFIX),
          vhosts: [],
          hide_node_vars: []
        }
      end

      def self.normalize_uri(uri_prefix)
        return '/' if uri_prefix.empty?

        uri_prefix.start_with?('/') ? uri_prefix : "/#{uri_prefix}"
      end
    end
  end
end
