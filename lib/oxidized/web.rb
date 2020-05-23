require 'json'

module Oxidized
  module API
    class Web
      require 'rack/handler'
      attr_reader :thread
      Rack::Handler::WEBrick = Rack::Handler.get(:puma)
      # in order to don't crash existing setup,
      # we set hide_enable at false by default
      def initialize nodes, listen, hide_enable=false
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
        WebApp.set :hide_enable, hide_enable
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
