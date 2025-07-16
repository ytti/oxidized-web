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
        @addr, @port, uri_prefix, vhosts = self.class.parse_configuration(configuration)
        uri_prefix = "/#{uri_prefix}"
        WebApp.set :nodes, nodes
        WebApp.set :host_authorization, { permitted_hosts: vhosts }
        @app = Rack::Builder.new do
          map uri_prefix do
            run WebApp
          end
        end
      end

      def run
        @thread = Thread.new do
          @server = Puma::Server.new @app
          @server.add_tcp_listener @addr, @port
          logger.info "Oxidized-web server listening on #{@addr}:#{@port}"
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
        addr = configuration.listen? || DEFAULT_HOST
        port = configuration.port? || DEFAULT_PORT
        uri_prefix = configuration.url_prefix? || DEFAULT_URI_PREFIX
        vhosts = configuration.vhosts? || []

        [addr, port, uri_prefix, vhosts]
      end

      # Legacy configuration style: "rest: 127.0.0.1:8888/prefix"
      def self.parse_legacy_configuration(configuration)
        listen, uri_prefix = configuration.split('/', 2)
        addr, _, port = listen.rpartition ':'
        unless port
          port = addr
          addr = nil
        end
        port = port.to_i
        uri_prefix ||= DEFAULT_URI_PREFIX
        vhosts = []

        [addr, port, uri_prefix, vhosts]
      end
    end
  end
end
