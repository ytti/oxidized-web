require 'bundler/gem_tasks'
require 'rake/testtask'

gemspec = Gem::Specification.load(Dir['*.gemspec'].first)
gemfile = "#{[gemspec.name, gemspec.version].join('-')}.gem"

# Integrate Rubocop if available
begin
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new
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
    t.verbose = false
  end
end

task build: %i[untracked chmod]

desc 'Abort if the gem would package files not tracked by git'
task :untracked do
  unless system('git rev-parse --is-inside-work-tree > /dev/null 2>&1')
    warn 'Not a git repository, skipping the check for untracked files'
    next
  end

  tracked = %x(git ls-files -z).split("\x0")
  untracked = gemspec.files - tracked
  next if untracked.empty?

  abort "The following files would be packaged but are not tracked by git:\n  " \
        "#{untracked.join("\n  ")}\nRemove them or add them to git."
end

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
  sh "git tag -a #{gemspec.version} -m 'Release #{gemspec.version}'"
end

desc 'Push the built gem to rubygems'
task :push do
  sh "gem push pkg/#{gemfile}"
end

# bundler/gem_tasks would tag "v<version>", Oxidized tags without the "v"
Rake::Task['release'].clear
desc 'Disabled, see docs/development.md'
task :release do
  abort 'Use `rake tag` and `rake push` as described in docs/development.md'
end

desc 'Normalize file permissions'
task :chmod do
  xbit = %w[]
  dirs = []
  (gemspec.files | xbit).each do |file|
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

task default: %i[rubocop test]
