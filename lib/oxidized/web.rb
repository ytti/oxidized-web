require 'json'

module Oxidized
  module API
    class Web
      require 'rack/handler/puma'
      attr_reader :thread

      def initialize(nodes, configuration)
        require 'oxidized/web/webapp'
        if configuration.instance_of? Asetus::ConfigStruct
          # New configuration syle: extentions.oxidized-web
          addr = configuration.listen? || '127.0.0.1'
          port = configuration.port? || 8888
          uri = configuration.url_prefix? || ''
          vhosts = configuration.vhosts? || []
        else
          # Old configuration stlyle: "rest: 127.0.0.1:8888/prefix"
          listen, uri = configuration.split '/'
          addr, _, port = listen.rpartition ':'
          unless port
            port = addr
            addr = nil
          end
          vhosts = []
        end
        uri = "/#{uri}"
        @opts = {
          Host: addr,
          Port: port
        }
        WebApp.set :nodes, nodes
        WebApp.set :host_authorization, { permitted_hosts: vhosts }
        @app = Rack::Builder.new do
          map uri do
            run WebApp
          end
        end
      end

      def run
        @thread = Thread.new do
          Rack::Handler::Puma.run @app, **@opts
          exit!
        end
      end
    end
  end
end
