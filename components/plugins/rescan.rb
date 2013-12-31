=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Allows users to skip the crawling phase by extracting paths discovered
# by a previous scan.
#
# It basically sets the 'scope_restrict_paths' framework option to the sitemap of
# a previous report.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Plugins::ReScan < Arachni::Plugin::Base

    def prepare
        framework.pause
        print_status "System paused."
    end

    def run
        framework.opts.scope_restrict_paths =
            Arachni::AuditStore.load( options['afr'] ).sitemap
        print_status "Found #{framework.opts.scope_restrict_paths.size} paths."
    end

    def clean_up
        framework.resume
        print_status "System resumed."
    end

    def self.info
        {
            name:        'ReScan',
            description: %q{It uses the AFR report of a previous scan to
                extract the sitemap in order to avoid a redundant crawl.
            },
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2',
            options:     [
                Options::Path.new( 'afr', [true, 'Path to the AFR report.'] )
            ]
        }
    end

end
