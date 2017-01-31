=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# HTTP PUT recon check.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::HttpPut < Arachni::Check::Base

    def self.substring
        @substring ||= 'PUT' + random_seed
    end

    def self.body
        @body ||= 'Created by Arachni. ' + substring
    end

    def run
        path = "#{get_path( page.url )}Arachni-#{random_seed}"
        return if audited?( path )
        audited( path )

        http.request( path, method: :put, body: self.class.body ) do |res|
            next if res.code != 201

            http.get( path ) do |c_res|
                check_and_log( c_res, res )

                # Try to DELETE the PUT file.
                http.request( path, method: :delete ){}
            end
        end
    end

    def check_and_log( response, put_response )
        return if !response.body.to_s.include?( self.class.substring )

        log(
            vector:   Element::Server.new( response.url ),
            response: put_response,
            proof:    put_response.status_line
        )
    end

    def self.info
        {
            name:        'HTTP PUT',
            description: %q{Checks if uploading files is possible using the HTTP PUT method.},
            elements:    [ Element::Server ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.2.3',

            issue:       {
                name:            %q{Publicly writable directory},
                description:     %q{
There are various methods in which a file (or files) may be uploaded to a
webserver. One method that can be used is the HTTP `PUT` method. The `PUT`
method is mainly used during development of applications and allows developers to
upload (or put) files on the server within the web root.

By nature of the design, the `PUT` method typically does not provide any filtering
and therefore allows sever side executable code (PHP, ASP, etc) to be uploaded to
the server.

Cyber-criminals will search for servers supporting the `PUT` method with the
intention of modifying existing pages, or uploading web shells to take control
of the server.

Arachni has discovered that the affected path allows clients to use the `PUT`
method. During this test, Arachni has `PUT` a file on the server within the web
root and successfully performed a `GET` request to its location and verified the
contents.
},
                references: {
                    'W3' => 'http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html'
                },
                tags:            %w(http methods put server),
                cwe:             650,
                severity:        Severity::HIGH,
                remedy_guidance: %q{
Where possible the HTTP `PUT` method should be globally disabled.
This can typically be done with a simple configuration change on the server.
The steps to disable the `PUT` method will differ depending on the type of server
being used (IIS, Apache, etc.).

For cases where the `PUT` method is required to meet application functionality,
such as REST style web services, strict limitations should be implemented to
ensure that only secure (SSL/TLS enabled) and authorised clients are permitted
to use the `PUT` method.

Additionally, the server's file system permissions should also enforce strict limitations.
}
            }
        }
    end

end
