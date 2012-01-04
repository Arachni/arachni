=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# Allows users to skip the crawling phase by extracting paths discovered
# by a previous scan.
#
# It basically sets the 'restrict_paths' framework option to the sitemap of
# a previous report.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class ReScan < Arachni::Plugin::Base

    def prepare
        @framework.pause!
        print_status( "System paused." )
    end

    def run
        @framework.opts.restrict_paths = Arachni::AuditStore.load( @options['afr'] ).sitemap
        print_status( "Found #{@framework.opts.restrict_paths.size} paths." )
    end

    def clean_up
        @framework.resume!
        print_status( "System resumed." )
    end

    def self.info
        {
            :name           => 'ReScan',
            :description    => %q{It uses the AFR report of a previous scan to
                extract the sitemap in order to avoid a redundant crawl.
            },
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptPath.new( 'afr', [ true, 'Path to the AFR report.' ] )
            ]
        }
    end

end

end
end
