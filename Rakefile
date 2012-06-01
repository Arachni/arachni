=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require 'bundler'
require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni/version'

begin
    require 'rspec'
    require 'rspec/core/rake_task'

    RSpec::Core::RakeTask.new
rescue LoadError => e
    puts 'If you want to run the tests please install rspec first:'
    puts '  gem install rspec'
end

desc "Generate docs"

task :docs do

    outdir = "../arachni-gh-pages"
    sh "mkdir #{outdir}" if !File.directory?( outdir )

    sh "inkscape gfx/logo.svg --export-png=#{outdir}/logo.png"
    sh "inkscape gfx/icon.svg --export-png=#{outdir}/icon.png"
    sh "inkscape gfx/icon.svg --export-png=#{outdir}/favicon.ico"
    sh "inkscape gfx/banner.svg --export-png=#{outdir}/banner.png"

    sh "yardoc --verbose --title \
      \"Arachni - Web Application Security Scanner Framework\" \
      external/* path_extractors/* plugins/* reports/* modules/* metamodules/* lib/* -o #{outdir} \
      - EXPLOITATION.md HACKING.md CHANGELOG.md LICENSE.md AUTHORS.md \
      CONTRIBUTORS.md ACKNOWLEDGMENTS.md"


    sh "rm -rf .yard*"
end


#
# Simple profiler using perftools[1].
#
# To install perftools for Ruby:
#   gem install perftools.rb
#
# [1] https://github.com/tmm1/perftools.rb
#
desc "Profile Arachni"
task :profile do
    sh "CPUPROFILE_FREQUENCY=500 CPUPROFILE=/tmp/profile.dat " +
        "RUBYOPT=\"-r`gem which perftools | tail -1`\" " +
        " ./bin/arachni http://demo.testfire.net && " +
        "pprof.rb --gif /tmp/profile.dat > profile.gif"
end

#
# Cleans reports and logs
#
desc "Cleaning report and log files."
task :clean do

    sh "rm error.log || true"
    sh "rm *.afr || true"
    sh "rm *.yaml || true"
    sh "rm *.json || true"
    sh "rm *.marshal || true"
    sh "rm *.gem || true"
    sh "rm logs/*.log || true"
    sh "rm spec/logs/*.log || true"
    sh "rm lib/arachni/ui/web/server/db/*.* || true"
    sh "rm lib/arachni/ui/web/server/db/welcomed || true"
    sh "rm lib/arachni/ui/web/server/public/reports/*.* || true"
    sh "rm lib/arachni/ui/web/server/tmp/*.* || true"
end


Bundler::GemHelper.install_tasks

#
# Building
#
# desc "Build the arachni gem."
# task :build  => [ :clean ] do
    # # sh "gem build arachni.gemspec"
    # Bundler::GemHelper.new.build_gem
# end

#
# Installing
#
# desc "Build and install the arachni gem."
# task :install  => [ :build ] do
    # sh "gem install arachni-#{Arachni::VERSION}.gem"
# end


#
# Publishing
#
desc "Push a new version to Gemcutter"
task :publish => [ :build ] do
    sh "gem push arachni-#{Arachni::VERSION}.gem"
end

desc "Build Arachni and run all the tests."
task :default => [ :build, :spec ]
