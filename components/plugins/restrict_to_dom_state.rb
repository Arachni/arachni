=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Arachni::Plugins::RestrictToDOMState < Arachni::Plugin::Base

    def prepare
        # Disable any operations that can lead to a crawl, we only want the
        # system to audit the page snapshot we give it.
        framework.options.scope.do_not_crawl

        @fragment = options[:fragment]
        @url      = "#{framework.options.url}##{@fragment}"

        print_info "Full URL set to: #{@url}"

        print_status 'Initialising browser...'
        browser = Arachni::Browser.new( store_pages: false )
        print_status '...done.'

        print_status 'Loading page...'
        page = browser.load( @url ).to_page
        print_info '  Transitions:'
        page.dom.print_transitions( method(:print_info), '    ' )

        framework.push_to_page_queue page, true
        print_status 'Pushed to page queue.'
    ensure
        return if !browser

        print_status 'Shutting down browser...'
        browser.shutdown
        print_status '...done.'
    end

    def self.info
        {
            name:        'Restrict to DOM state',
            description: %q{Restricts the scan to a single page's DOM state.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.1',
            options:     [
                Options::String.new( :fragment,
                    required:    true,
                    description: 'URL fragment for the desired state.'
                )
            ],
            priority:    1
        }
    end

end
