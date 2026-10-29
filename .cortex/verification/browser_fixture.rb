ENV['APP_ENV'] = 'test'
$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)
require 'oxidized'
require 'oxidized/web'
require 'oxidized/web/webapp'
require 'puma'
class FixtureNodes
  class Stats
    def successes = 5
    def failures = 1

    def get(status)
      [{ end: Time.now - (status == :success ? 60 : 3600), time: 1.2 }]
    end
  end

  def list
    %w[core-cisco branch-mikrotik offline-switch].each_with_index.map do |name, index|
      { name: name, full_name: name, ip: "192.0.2.#{index + 1}",
        model: index == 1 ? 'routeros' : 'ios', group: 'lab', mtime: Time.now - 600,
        last: { status: index == 2 ? :no_connection : :success, end: Time.now - 60 } }
    end
  end

  def each(&block)
    list.map { |node| Struct.new(:name, :stats).new(node[:name], Stats.new) }.each(&block)
  end

  def version(*)
    [{ oid: 'new', time: Time.now - 60 }, { oid: 'old', time: Time.now - 3600 }]
  end

  def get_version(*) = "hostname core-cisco\ninterface Ethernet1\n description Configuration snapshot\n"
  def fetch(*) = get_version

  def get_diff(*)
    { patch: "diff --git a/config b/config\n--- a/config\n+++ b/config\n@@ -1 +1 @@\n-old description\n+new description\n", stat: [1, 1] }
  end

  def show(*) = { name: 'core-cisco', model: 'ios', vars: {} }
end
Oxidized::API::WebApp.set :nodes, FixtureNodes.new
server = Puma::Server.new(Oxidized::API::WebApp)
server.add_tcp_listener '127.0.0.1', 9299
server.run.join
