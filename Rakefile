require 'bundler/gem_tasks'
require 'rake/testtask'

gemspec = eval(File.read(Dir['*.gemspec'].first))
gemfile = "#{[gemspec.name, gemspec.version].join('-')}.gem"

# Integrate Rubocop if available
begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new
  task(:default).prerequisites << task(:rubocop)
rescue LoadError
  task :rubocop do
    puts 'Install rubocop to run its rake tasks'
  end
end

desc 'Validate gemspec'
task :gemspec do
  gemspec.validate
end

desc 'Run minitest'
task :test do
  Rake::TestTask.new do |t|
    t.libs << 'spec'
    t.test_files = FileList['spec/**/*_spec.rb']
    t.ruby_opts = ['-W:deprecated']
    t.warning = true
    t.verbose = true
  end
end

task build: :chmod
## desc 'Install gem'
## task :install => :build do
##   system "sudo -Es sh -c \'umask 022; gem install gems/#{file}\'"
## end

desc 'Remove gems'
task :clean do
  FileUtils.rm_rf 'pkg'
end

desc 'Tag the release'
task :tag do
  system "git tag #{gemspec.version} -m 'Release #{gemspec.version}'"
end

desc 'Push to rubygems'
task push: :tag do
  system "gem push pkg/#{gemfile}"
end

desc 'Normalise file permissions'
task :chmod do
  xbit = %w[]
  dirs = []
  %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }.each do |file|
    dirs.push(File.dirname(file))
    xbit.include?(file) ? File.chmod(0o0755, file) : File.chmod(0o0644, file)
  end
  dirs.sort.uniq.each { |dir| File.chmod(0o0755, dir) }
end

desc 'Copy web packages from npm into public'
task :weblibs do
  weblibs = []
  fonts = []

  # jQuery
  weblibs << 'node_modules/jquery/dist/jquery.js'

  # Bootstrap
  weblibs << 'node_modules/bootstrap/dist/js/bootstrap.js'
  weblibs << 'node_modules/bootstrap/dist/js/bootstrap.js.map'
  weblibs << 'node_modules/bootstrap/dist/css/bootstrap.css'
  weblibs << 'node_modules/bootstrap/dist/css/bootstrap.css.map'
  weblibs << 'node_modules/bootstrap/dist/js/bootstrap.bundle.js'
  weblibs << 'node_modules/bootstrap/dist/js/bootstrap.bundle.js.map'

  # Bootstrap-icons
  weblibs << 'node_modules/bootstrap-icons/font/bootstrap-icons.css'
  fonts << 'node_modules/bootstrap-icons/font/fonts/bootstrap-icons.woff'
  fonts << 'node_modules/bootstrap-icons/font/fonts/bootstrap-icons.woff2'

  # Datatables
  weblibs << 'node_modules/datatables.net/js/dataTables.js'

  # Datatables + Bootstrap
  weblibs << 'node_modules/datatables.net-bs5/js/dataTables.bootstrap5.js'
  weblibs << 'node_modules/datatables.net-bs5/css/dataTables.bootstrap5.css'

  # Datatables Buttons + Bootstrap
  weblibs << 'node_modules/datatables.net-buttons-bs5/js/buttons.bootstrap5.js'
  weblibs << 'node_modules/datatables.net-buttons-bs5/css/buttons.bootstrap5.css'
  # colVis
  weblibs << 'node_modules/datatables.net-buttons/js/dataTables.buttons.js'
  weblibs << 'node_modules/datatables.net-buttons/js/buttons.colVis.js'

  # dayjs
  weblibs << 'node_modules/dayjs/dayjs.min.js'
  weblibs << 'node_modules/dayjs-plugin-utc/dist/dayjs-plugin-utc.min.js'

  weblibs.each do |w|
    cp(w, 'lib/oxidized/web/public/weblibs')
  end

  fonts.each do |f|
    cp(f, 'lib/oxidized/web/public/weblibs/fonts')
  end
end

task default: :test
