require 'json'

module Oxidized
  module API
    class Web
      require 'rack/handler'
      attr_reader :thread
      Rack::Handler::WEBrick = Rack::Handler.get(:puma)
      def initialize nodes, listen
        require 'oxidized/web/webapp'
        listen, uri = listen.split '/'
        addr, _, port = listen.rpartition ':'
        port, addr = addr, nil if not port
        uri = '/' + uri.to_s
        @opts = {
          Host: addr,
          Port: port,
        }
        WebApp.set :nodes, nodes
        @app = Rack::Builder.new do
          map uri do
            run WebApp
          end
        end
      end

      def run
        @thread = Thread.new { Rack::Handler::Puma.run @app, @opts }
      end
    end
  end
end
