=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

#
# Publishing
#
desc "Push a new version to Gemcutter"
task :publish do

    require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/arachni'

    sh "gem build arachni.gemspec"
    sh "gem push arachni-#{Arachni::VERSION}.gem"
end
