=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'bundler'
require 'fileutils'
require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni'

begin
    require 'rspec'
    require 'rspec/core/rake_task'

    namespace :spec do

        desc 'Run core library tests.'
        RSpec::Core::RakeTask.new( :core ) do |t|
            t.pattern = FileList[ 'spec/arachni/**/*_spec.rb' ]
        end

        desc 'Run check tests.'
        RSpec::Core::RakeTask.new( :checks ) do |t|
            t.pattern = FileList[ 'spec/components/checks/**/*_spec.rb' ]
        end

        namespace :checks do
            desc 'Run tests for the active checks.'
            RSpec::Core::RakeTask.new( :active ) do |t|
                t.pattern = FileList[ 'spec/components/checks/active/**/*_spec.rb' ]
            end

            desc 'Run tests for the passive checks.'
            RSpec::Core::RakeTask.new( :passive ) do |t|
                t.pattern = FileList[ 'spec/components/checks/passive/**/*_spec.rb' ]
            end
        end

        desc 'Run reporter tests.'
        RSpec::Core::RakeTask.new( :reporters ) do |t|
            t.pattern = FileList[ 'spec/components/reporters/*_spec.rb' ]
        end

        desc 'Run plugin tests.'
        RSpec::Core::RakeTask.new( :plugins ) do |t|
            t.pattern = FileList[ 'spec/components/plugins/**/*_spec.rb' ]
        end

        desc 'Run path-extractor tests.'
        RSpec::Core::RakeTask.new( :path_extractors ) do |t|
            t.pattern = FileList[ 'spec/components/path_extractors/**/*_spec.rb' ]
        end

        desc 'Run fingerprinter tests.'
        RSpec::Core::RakeTask.new( :fingerprinters ) do |t|
            t.pattern = FileList[ 'spec/components/fingerprinters/**/*_spec.rb' ]
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
                        t.pattern = FileList[ 'spec/external/wavsep/active/xss*_spec.rb' ]
                    end

                    desc 'Run the WAVSEP SQL injection tests.'
                    RSpec::Core::RakeTask.new( :sql_injection ) do |t|
                        t.pattern = FileList[ 'spec/external/wavsep/active/sql_injection_spec.rb' ]
                    end

                    desc 'Run the WAVSEP LFI tests.'
                    RSpec::Core::RakeTask.new( :lfi ) do |t|
                        t.pattern = FileList[ 'spec/external/wavsep/active/lfi_spec.rb' ]
                    end

                    desc 'Run the WAVSEP RFI tests.'
                    RSpec::Core::RakeTask.new( :rfi ) do |t|
                        t.pattern = FileList[ 'spec/external/wavsep/active/rfi_spec.rb' ]
                    end

                    desc 'Run the WAVSEP Unvalidated Redirect tests.'
                    RSpec::Core::RakeTask.new( :unvalidated_redirect ) do |t|
                        t.pattern = FileList[ 'spec/external/wavsep/active/unvalidated_redirect_spec.rb' ]
                    end

                    desc 'Run the WAVSEP Obsolete Files tests.'
                    RSpec::Core::RakeTask.new( :obsolete_files ) do |t|
                        t.pattern = FileList[ 'spec/external/wavsep/active/obsolete_files_spec.rb' ]
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
                    RSpec::Core::RakeTask.new( :sql_injection ) do |t|
                        t.pattern = FileList[ 'spec/external/wavsep/false_positives/sql_injection_spec.rb' ]
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

        desc 'Generate an AFR report for the reporter tests.'
        namespace :generate do
            task :afr do
                begin
                    $spec_issues = []

                    RSpec::Core::Runner.run(FileList[ 'spec/components/checks/**/*_spec.rb' ])

                    ($spec_issues.size / 3).times do |i|
                        # Add remarks to some issues.
                        issue = $spec_issues.sample
                        issue.add_remark( :stuff, 'Blah' )
                        issue.add_remark( :stuff, 'Blah2' )

                        issue.add_remark( :stuff2, '2 Blah' )
                        issue.add_remark( :stuff2, '2 Blah2' )

                        # Flag some issues as untrusted.
                        $spec_issues.sample.trusted = false
                    end

                    Arachni::Data.issues.store
                    $spec_issues.each { |i| Arachni::Data.issues << i }

                    Arachni::Options.url = 'http://test.com'
                    Arachni::Options.audit.elements Arachni::Page::ELEMENTS - [:link_templates]
                    Arachni::Options.audit.link_templates = [
                        /\/input\/(?<input>.+)\//,
                        /input\|(?<input>.+)/
                    ]

                    Arachni::Report.new(
                        sitemap: { Arachni::Options.url => 200 },
                        issues:  Arachni::Data.issues.sort
                    ).save( 'spec/support/fixtures/report.afr' )
                ensure
                    Arachni::Options.reset
                    Arachni::Data.reset
                end
            end
        end
    end

    RSpec::Core::RakeTask.new
rescue LoadError
    puts 'If you want to run the tests please install rspec first:'
    puts '  gem install rspec'
end

desc 'Start a web server dispatcher.'
task :web_server_dispatcher do
    require_relative 'spec/support/lib/web_server_dispatcher'

    WebServerDispatcher.new
end

desc 'Generate docs.'
task :docs do
    outdir = "../arachni-docs"
    sh "rm -rf #{outdir}"
    sh "mkdir -p #{outdir}"

    sh "yardoc -o #{outdir}"

    sh "rm -rf .yardoc"
end

desc 'Remove reporter and log files.'
task :clean do
    files = %w(error.log *.afr *.afs *.yaml *.json *.marshal *.gem pkg/*.gem
        snapshots/*.afs logs/*.log spec/support/logs/*.log).map { |file| Dir.glob( file ) }.flatten

    next if files.empty?

    puts 'Removing:'
    files.each { |file| puts "  * #{file}" }
    FileUtils.rm files
end

Bundler::GemHelper.install_tasks

desc 'Push a new version to RubyGems'
task :publish => [ :release ]

desc 'Build Arachni and run all the tests.'
task :default => [ :build, :spec ]
