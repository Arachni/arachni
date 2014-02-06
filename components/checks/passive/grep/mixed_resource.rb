=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Mixed Resource detection check
#
# Looks for resources served over HTTP when the HTML code is server over HTTPS.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.3
#
# @see http://googleonlinesecurity.blogspot.com/2011/06/trying-to-end-mixed-scripting.html
class Arachni::Checks::MixedResource < Arachni::Check::Base

    def run
        return if !https?( page.url ) || !page.document

        print_status 'Checking...'

        page.document.css( 'script' ).each do |script|
            url = script.attributes['src'].to_s
            log_resource( url ) if insecure_script?( script )
        end

        page.document.css( 'link' ).each do |script|
            url = script.attributes['href'].to_s
            log_resource( url ) if insecure_link?( script )
        end
    end

    def insecure_link?( script )
        url = script.attributes['href'].to_s
        url && !url.empty? && script.attributes['rel'].to_s.downcase == 'stylesheet' &&
            !https?( url )
    end

    def insecure_script?( script )
        url = script.attributes['src'].to_s
        url && !url.empty? && !https?( url )
    end

    def https?( url )
        uri_parse( to_absolute( url, page.url ) ).scheme == 'https'
    end

    def log_resource( url )
        return if audited?( url )
        audited( url )

        match_and_log( url )
    end

    def self.info
        {
            name:        'Mixed Resource',
            description: %q{Looks for resources served over HTTP when the HTML code is server over HTTPS.},
            elements:    [ Element::Body ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            version:     '0.1.2',

            issue:       {
                name:            %q{Mixed Resource},
                description:     %q{Serving resources over an unencrypted channel
    while the HTML code is served over HTTPS can lead to
    Man-In-The-Middle attacks and provide a false sense of security.},
                references:      {
                    'Google Online Security Blog' =>
                        'http://googleonlinesecurity.blogspot.com/2011/06/trying-to-end-mixed-scripting.html'
                },
                tags:            %w(unencrypted resource javascript stylesheet),
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{Configure the server to serve all resources over the encrypted channel.}
            }

        }
    end

end
