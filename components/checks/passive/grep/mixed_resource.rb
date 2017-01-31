=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Mixed Resource detection check
#
# Looks for resources served over HTTP when the HTML code is server over HTTPS.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @see http://googleonlinesecurity.blogspot.com/2011/06/trying-to-end-mixed-scripting.html
class Arachni::Checks::MixedResource < Arachni::Check::Base

    def run
        return if !https?( page.url ) || !page.document

        print_status 'Checking...'

        page.document.nodes_by_name( 'script' ).each do |script|
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
        url && !url.empty? && script.attributes['rel'].to_s.downcase == 'stylesheet' &&
            !https?( url )
    end

    def insecure_script?( script )
        url = script.attributes['src'].to_s
        return if url.empty?

        parsed = uri_parse( to_absolute( url, page.url ) )
        # Ignore resources injected by the browser required to do its job.
        return if !parsed || parsed.domain == 'browser.arachni'

        !https?( url )
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
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
            version:     '0.1.5',

            issue:       {
                name:            %q{Mixed Resource},
                description:     %q{
The HTTP protocol by itself is clear text, meaning that any data that is
transmitted via HTTP can be captured and the contents viewed. To keep data
privateand prevent it from being intercepted, HTTP is often tunnelled through
either a Secure Sockets Layer (SSL), or Transport Layer Security (TLS) connection.
When either of these encryption standards are used, it is referred to as HTTPS.

Cyber-criminals will often attempt to compromise sensitive information passed
from the client to the server using HTTP.
This can be conducted via various different Man-in-The-Middle (MiTM) attacks or
through network packet captures.

Arachni discovered that the affected site is utilising both HTTP and HTTPS. While
the HTML code is served over HTTPS, the server is also serving resources over an
unencrypted channel, which can lead to the compromise of data, while providing a
false sense of security to the user.
},
                references:      {
                    'Google Online Security Blog' =>
                        'http://googleonlinesecurity.blogspot.com/2011/06/trying-to-end-mixed-scripting.html'
                },
                tags:            %w(unencrypted resource javascript stylesheet),
                severity:        Severity::MEDIUM,
                remedy_guidance: %q{
All pages and/or resources on the affected site should be secured equally,
utilising the latest and most secure encryption protocols. These include SSL
version 3.0 and TLS version 1.2.

While TLS 1.2 is the latest and the most preferred protocol, not all browsers
will support this encryption method. Therefore, the more common SSL is included.
Older protocols such as SSL version 2, and weak ciphers (< 128 bit) should also
be disabled.
}
            }
        }
    end

end
