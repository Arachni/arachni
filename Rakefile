=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

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
        " ./bin/arachni http://demo.testfire.net --link-count=5 && " +
        "pprof.rb --gif /tmp/profile.dat > profile.gif"
end

#
# Cleans reports and logs
#
desc "Cleaning report and log files."
task :clean do

    sh "rm *.afr || true"
    sh "rm *.gem || true"
    sh "rm logs/*.log || true"
    sh "rm lib/ui/web/server/db/log.db || true"
    sh "rm lib/ui/web/server/db/default.db || true"
    sh "rm lib/ui/web/server/db/welcomed || true"
end


#
# Building
#
desc "Build the arachni gem."
task :build  => [ :clean ] do

    require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni'

    sh "gem build arachni.gemspec"
end


#
# Installing
#
desc "Build and install the arachni gem."
task :install  => [ :build ] do

    require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni'

    sh "gem install arachni-#{Arachni::VERSION}.gem"
end


#
# Publishing
#
desc "Push a new version to Gemcutter"
task :publish => [ :build ] do

    require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni'

    sh "gem push arachni-#{Arachni::VERSION}.gem"
end
