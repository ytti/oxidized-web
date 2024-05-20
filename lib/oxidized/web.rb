require 'json'

module Oxidized
  module API
    class Web
      require 'rack/handler/puma'
      attr_reader :thread

      def initialize(nodes, listen)
        require 'oxidized/web/webapp'
        listen, uri = listen.split '/'
        addr, _, port = listen.rpartition ':'
        unless port
          port = addr
          addr = nil
        end
        uri = '/' + uri.to_s
        @opts = {
          Host: addr,
          Port: port
        }
        WebApp.set :nodes, nodes
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
