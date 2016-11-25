=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Looks External Resource
#
# @author Lionel PRAT <lionel.prat9@gmail.com>
class Arachni::Checks::External_resource < Arachni::Check::Base

    def run
        return if !page.document

        print_status 'Checking...'

        page.document.nodes_by_name( 'script' ).each do |script|
            url = script.attributes['src'].to_s
            log_resource( url ) if insecure_script?( script )
        end
        
       page.document.nodes_by_name( 'img' ).each do |script|
            url = script.attributes['src'].to_s
            log_resource( url ) if insecure_script?( script )
        end

        page.document.nodes_by_name( 'link' ).each do |script|
            url = script.attributes['href'].to_s
            log_resource( url ) if insecure_link?( script )
        end
    end

    def insecure_link?( script )
        url = script.attributes['href'].to_s
        url && !url.empty? && !extern?( url )
        #script.attributes['rel'].to_s.downcase == 'stylesheet' &&
    end

    def insecure_script?( script )
        url = script.attributes['src'].to_s
        return if url.empty?

        parsed = uri_parse( to_absolute( url, page.url ) )
        # Ignore resources injected by the browser required to do its job.
        return if !parsed || parsed.domain == 'browser.arachni'

        !extern?( url )
    end

    def extern?( url )
        uri_parse( to_absolute( url, page.url ) ).host.to_s.downcase == page.parsed_url.host.to_s.downcase 
    end

    def log_resource( url )
        return if audited?( url )
        audited( url )

        match_and_log( url )
    end

    def self.info
        {
            name:        'External Resource',
            description: %q{Looks for resources external.},
            elements:    [ Element::Body ],
            author:      'Lionel PRAT <lionel.prat9@gmail.com> ',
            version:     '0.0.1',

            issue:       {
                name:            %q{External Resource},
                description:     %q{
When use external resource, the host externe can remove in futur or host can to be hacked. Use external ressource is dangerous.
},
                tags:            %w(External ressource),
                severity:        Severity::LOW,
                remedy_guidance: %q{
Downlaod resource and use localy.
}
            }
        }
    end

end
