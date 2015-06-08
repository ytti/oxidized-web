require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/url_for'
require 'haml'
require 'sass'
require 'pp'
require 'pp'
require 'oxidized/web/mig'
module Oxidized
  module API
    class WebApp < Sinatra::Base
      helpers Sinatra::UrlForHelper
      set :public_folder, Proc.new { File.join(root, "public") }
      
      get '/' do
        redirect url_for('/nodes')
      end

      get '/nodes.?:format?' do
        @data = nodes.list.map do |node|
          node[:status]    = 'never'
          node[:time]      = 'never'
          node[:group]     = 'default' unless node[:group]
          if node[:last]
            node[:status] = node[:last][:status]
            node[:time]   = node[:last][:end]
          end
          node
        end
        out :nodes
      end

      get '/nodes/stats.?:format?' do
        @data = {}
        nodes.each do |node|
          @data[node.name] = node.stats.get
        end
        out :stats
      end

      get '/reload.?:format?' do
        nodes.load
        @data = 'reloaded list of nodes'
        out
      end

      get '/node/fetch/:node' do
        begin
          node, @json = route_parse :node
          @data = nodes.fetch node, nil
        rescue NodeNotFound => error
          @data = error.message
        end
        out :text
      end

      get '/node/fetch/:group/:node' do
        node, @json = route_parse :node
        @data = nodes.fetch node, params[:group]
        out :text
      end

      get '/node/next/:node' do
        node, @json = route_parse :node
        begin
          nodes.next node
        rescue NodeNotFound
        end
        redirect url_for('/nodes') unless @json
        @data = 'ok'
        out
      end

      # use this to attach author/email/message to commit
      put '/node/next/:node' do
        node, @json = route_parse :node
        opt = JSON.load request.body.read
        nodes.next node, opt
        redirect url_for('/nodes') unless @json
        @data = 'ok'
        out
      end

      get '/node/show/:node' do
        node, @json = route_parse :node
        @data = nodes.show node
        out :node
      end
      
      #redirect to the web page for rancid - oxidized migration
      get '/migration' do
        out :migration
      end
      
      #get the files send
      post '/migration' do
        number = params[:number].to_i
        cloginrc_file = params['cloginrc'][:tempfile]
        path_new_file = params['path_new_file']

        router_db_files = Array.new
        
        i = 1
        while i <= number do
          router_db_files.push({:file=>(params["file"+i.to_s][:tempfile]), :group=>params["group"+i.to_s]})
          i = i+1
        end

        migration = Mig.new(router_db_files, cloginrc_file, path_new_file)
        migration.go_rancid_migration
        redirect url_for("//nodes")
     
      end
      
      get '/css/*.css' do
        sass "sass/#{params[:splat].first}".to_sym
      end
      
      private

      def out template=:default
        if @json or params[:format] == 'json'
          json @data
        elsif template == :text
          content_type :text
          @data
        else
          haml template, :layout => true
        end
      end

      def nodes
        settings.nodes
      end

      def route_parse param
        json = false
        e = params[param].split '.'
        if e.last == 'json'
          e.pop
          json = true
        end
        [e.join('.'), json]
      end
    end
  end
end
