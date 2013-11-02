=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'bundler'
require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni'

begin
    require 'rspec'
    require 'rspec/core/rake_task'

    namespace :spec do

        desc 'Run core library tests.'
        RSpec::Core::RakeTask.new( :core ) do |t|
            t.pattern = FileList[ 'spec/arachni/**/*_spec.rb' ]
        end

        desc 'Run module tests.'
        RSpec::Core::RakeTask.new( :modules ) do |t|
            t.pattern = FileList[ 'spec/modules/**/*_spec.rb' ]
        end

        desc 'Run report tests.'
        RSpec::Core::RakeTask.new( :reports ) do |t|
            t.pattern = FileList[ 'spec/reports/**/*_spec.rb' ]
        end

        desc 'Run plugin tests.'
        RSpec::Core::RakeTask.new( :plugins ) do |t|
            t.pattern = FileList[ 'spec/plugins/**/*_spec.rb' ]
        end

        desc 'Run path-extractor tests.'
        RSpec::Core::RakeTask.new( :path_extractors ) do |t|
            t.pattern = FileList[ 'spec/path_extractors/**/*_spec.rb' ]
        end

        desc 'Run external test suites.'
        RSpec::Core::RakeTask.new( :external ) do |t|
            t.pattern = FileList[ 'spec/external/**/*_spec.rb' ]
        end

        namespace :external do

            desc 'Run the WAVSEP test suite.'
            RSpec::Core::RakeTask.new( :wavsep ) do |t|
                t.pattern = FileList[ 'spec/external/wavsep/**/**/*_spec.rb' ]
            end

            namespace :wavsep do

                desc 'Run the WAVSEP active tests.'
                RSpec::Core::RakeTask.new( :active ) do |t|
                    t.pattern = FileList[ 'spec/external/wavsep/active/**/*_spec.rb' ]
                end

                namespace :active do

                    desc 'Run the WAVSEP XSS tests.'
                    RSpec::Core::RakeTask.new( :xss ) do |t|
                        t.pattern = FileList[ 'spec/external/wavsep/active/xss_spec.rb' ]
                    end

                    desc 'Run the WAVSEP SQL injection tests.'
                    RSpec::Core::RakeTask.new( :sqli ) do |t|
                        t.pattern = FileList[ 'spec/external/wavsep/active/sqli_spec.rb' ]
                    end

                    desc 'Run the WAVSEP LFI tests.'
                    RSpec::Core::RakeTask.new( :lfi ) do |t|
                        t.pattern = FileList[ 'spec/external/wavsep/active/lfi_spec.rb' ]
                    end

                    desc 'Run the WAVSEP RFI tests.'
                    RSpec::Core::RakeTask.new( :rfi ) do |t|
                        t.pattern = FileList[ 'spec/external/wavsep/active/rfi_spec.rb' ]
                    end
                end

                desc 'Run the WAVSEP false positive tests.'
                RSpec::Core::RakeTask.new( :false_positives ) do |t|
                    t.pattern = FileList[ 'spec/external/wavsep/false_positives/**/*_spec.rb' ]
                end

                namespace :false_positives do
                    desc 'Run the WAVSEP XSS false positive tests.'
                    RSpec::Core::RakeTask.new( :xss ) do |t|
                        t.pattern = FileList[ 'spec/external/wavsep/false_positives/xss_spec.rb' ]
                    end

                    desc 'Run the WAVSEP SQL injection false positive tests.'
                    RSpec::Core::RakeTask.new( :sqli ) do |t|
                        t.pattern = FileList[ 'spec/external/wavsep/false_positives/sqli_spec.rb' ]
                    end

                    desc 'Run the WAVSEP LFI false positive tests.'
                    RSpec::Core::RakeTask.new( :lfi ) do |t|
                        t.pattern = FileList[ 'spec/external/wavsep/false_positives/lfi_spec.rb' ]
                    end

                    desc 'Run the WAVSEP RFI false positive tests.'
                    RSpec::Core::RakeTask.new( :rfi ) do |t|
                        t.pattern = FileList[ 'spec/external/wavsep/false_positives/rfi_spec.rb' ]
                    end
                end
            end
        end

        desc 'Generate an AFR report for the report tests.'
        namespace :generate do
            task :afr do

                # Run the module tests and save all the issues to put them
                # in our AFR report.
                FileUtils.touch( "#{Dir.tmpdir}/save_issues" )
                Rake::Task['spec:modules'].execute rescue nil
                FileUtils.rm( "#{Dir.tmpdir}/save_issues" )

                issues = []
                File.open( "#{Dir.tmpdir}/issues.yml" ) do |f|
                    issues = YAML.load_documents( f ).flatten
                end

                200.times do |i|
                    # Add remarks to some issues.
                    issue = issues[rand( issues.size )]
                    issue.add_remark( :stuff, 'Blah' )
                    issue.add_remark( :stuff, 'Blah2' )

                    # Flag some issues are requiring manual verification.
                    issues[rand( issues.size )].verification = true
                end

                FileUtils.rm( "#{Dir.tmpdir}/issues.yml" )

                Arachni::Options.url = 'http://test.com'
                Arachni::Options.audit :forms, :links, :cookies, :headers

                # Make all module constants available because the AuditStore
                # will need them to make the necessary associations between them
                # and the issues.
                Arachni::Framework.new.modules.load_all

                Arachni::AuditStore.new( issues: issues.uniq ).
                    save( 'spec/support/fixtures/auditstore.afr' )

                Arachni::Options.reset
            end
        end
    end

    RSpec::Core::RakeTask.new
rescue LoadError
    puts 'If you want to run the tests please install rspec first:'
    puts '  gem install rspec'
end

desc 'Generate docs.'
task :docs do

    outdir = "../arachni-docs"
    sh "rm -rf #{outdir}"
    sh "mkdir -p #{outdir}"

    sh "yardoc -o #{outdir}"

    sh "rm -rf .yardoc"
end

desc 'Generate graphics.'
task :gfx do

    outdir = 'gfx/compiled'
    srcdir = 'gfx/source'

    sh 'mkdir -p ~/.fonts'
    sh 'cp gfx/font/Beneath_the_Surface.ttf ~/.fonts'

    Dir.glob( "#{srcdir}/*.svg" ).each do |src|
        sh "inkscape #{src} --export-png=#{outdir}/#{File.basename( src, '.svg' )}.png"
    end

    cp "#{outdir}/icon.png", "#{outdir}/favicon.ico"

    sh 'rm -f ~/.fonts/Beneath_the_Surface.ttf'
end

#
# Simple profiler using perftools[1].
#
# To install perftools for Ruby:
#   gem install perftools.rb
#
# [1] https://github.com/tmm1/perftools.rb
#
desc 'Profile Arachni.'
task :profile do

    if !Gem::Specification.find_all_by_name( 'perftools.rb' ).empty?
        sh "CPUPROFILE_FREQUENCY=500 CPUPROFILE=/tmp/profile.dat " +
               "RUBYOPT=\"-r`gem which perftools | tail -1`\" " +
               " ./bin/arachni http://demo.testfire.net && " +
               "pprof.rb --gif /tmp/profile.dat > profile.gif"
    else
        puts 'If you want to run the profiler please install perftools.rb first:'
        puts '  gem install perftools.rb'
    end

end

desc 'Remove report and log files.'
task :clean do

    sh "rm error.log || true"
    sh "rm *.afr || true"
    sh "rm *.yaml || true"
    sh "rm *.json || true"
    sh "rm *.marshal || true"
    sh "rm *.gem || true"
    sh "rm logs/*.log || true"
    sh "rm spec/support/logs/*.log || true"
end


Bundler::GemHelper.install_tasks

desc 'Push a new version to RubyGems'
task :publish => [ :release ]

desc 'Build Arachni and run all the tests.'
task :default => [ :build, :spec ]
