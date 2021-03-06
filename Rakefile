%w[rubygems hoe rake rake/clean fileutils newgem thread rubigen].each { |f|
  require f
}

require 'rspec'
require 'rspec/core/rake_task'

gem "rspec", :require => "spec/rake/spectask"

require File.dirname(__FILE__) + '/lib/activefacts'

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec('activefacts') do |p|
  p.version = ActiveFacts::VERSION
  p.summary = "A semantic modeling and query language (CQL) and application runtime (the Constellation API)"
  p.description = %q{
ActiveFacts provides a semantic modeling language, the Constellation
Query Language (CQL).  CQL combines natural language verbalisation and
formal logic, producing a formal language that reads like plain
English. ActiveFacts converts semantic models from CQL to relational
and object models in SQL, Ruby and other languages.
}
  p.url = "http://dataconstellation.com/ActiveFacts/"
  p.developer('Clifford Heath', 'cjh@dataconstellation.org')
  p.changes              = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  p.post_install_message = 'For more information on ActiveFacts, see http://dataconstellation.com/ActiveFacts'
  p.rubyforge_name       = "cjheath@rubyforge.org"
  p.extra_deps         = [
    ['activefacts-api','>= 0.8.10'],
    ['treetop','>= 1.4.1'],
    ['rake','>= 0.8.7'],
  ]
  p.extra_dev_deps = [
    ['newgem', ">= #{::Newgem::VERSION}"]
  ]
  p.spec_extras[:extensions] = 'lib/activefacts/cql/Rakefile'
  # Magic Hoe hook to prevent the generation of diagrams:
  ENV['NODOT'] = 'yes'
  p.spec_extras[:rdoc_options] = ['-S'] +
    # RDoc used to have these options: -A has_one -A one_to_one -A maybe
    %w{
      -x lib/activefacts/cql/.*.rb
      -x lib/activefacts/vocabulary/.*.rb
    }
  p.clean_globs |= %w[**/.DS_Store tmp *.log]
  path = (p.rubyforge_name == p.name) ? p.rubyforge_name : "\#{p.rubyforge_name}/\#{p.name}"
  p.remote_rdoc_dir = File.join(path.gsub(/^#{p.rubyforge_name}\/?/,''), 'rdoc')
  p.rsync_args = '-av --delete --ignore-errors'
end

require 'newgem/tasks' # load /tasks/*.rake
Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# task :default => [:spec, :features]

RSpec::Core::RakeTask.new do |t|
    t.ruby_opts = ['-I', "lib"]
    # t.pattern = FileList['spec/**/*_spec.rb']
    # t.rcov = true
    # t.rcov_opts = ['--exclude', 'spec,/usr/lib/ruby' ]
end
