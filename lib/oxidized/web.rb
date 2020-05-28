require 'json'
require 'uri'

module Oxidized
  module API
    class Web
      require 'rack/handler'
      attr_reader :thread
      Rack::Handler::WEBrick = Rack::Handler.get(:puma)
      def initialize nodes, listen
        require 'oxidized/web/webapp'

        listen.prepend("http://") if not listen.start_with?("http://")
        url = URI(listen)
        addr = url.host
        port = url.port
        uri = url.path
        uri.prepend("/") if not url.path.start_with?("/")

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
        @thread = Thread.new do
          Rack::Handler::Puma.run @app, @opts
          exit!
        end
      end
    end
  end
end
