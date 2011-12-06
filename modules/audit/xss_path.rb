=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# XSS in path audit module.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.5
#
# @see http://cwe.mitre.org/data/definitions/79.html
# @see http://ha.ckers.org/xss.html
# @see http://secunia.com/advisories/9716/
#
class XSSPath < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )
    end

    def prepare
        @_tag_name = 'my_tag_' + seed
        @str = '<' + @_tag_name + ' />'
        @__injection_strs = [
            @str,
            '?' + @str,
            '?>"\'>' + @str,
            '?=>"\'>' + @str
        ]

        @@audited ||= Set.new
    end

    def run
        path = get_path( @page.url )

        return if @@audited.include?( path )
        @@audited << path

        @__injection_strs.each {
            |str|

            url  = path + str

            print_status( "Checking for: #{url}" )

            req  = @http.get( url )

            req.on_complete {
                |res|
                check_and_log( res, str )
            }
        }
    end

    def check_and_log( res, str )
        # check for the existence of the tag name before parsing to verify
        # no reason to waste resources...
        return if ! res.body.substring?( @_tag_name )

        doc = Nokogiri::HTML( res.body )

        # see if we managed to successfully inject our element
        if !doc.xpath( "//#{@_tag_name}" ).empty?
            __log_results( res, str )
        end
    end


    def self.info
        {
            :name           => 'XSSPath',
            :description    => %q{Cross-Site Scripting module for path injection},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1.5',
            :references     => {
                'ha.ckers' => 'http://ha.ckers.org/xss.html',
                'Secunia'  => 'http://secunia.com/advisories/9716/'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Cross-Site Scripting (XSS) in path},
                :description => %q{Client-side code, like JavaScript, can
                    be injected into the web application.},
                :tags        => [ 'xss', 'path', 'injection', 'regexp' ],
                :cwe         => '79',
                :severity    => Issue::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

    def __log_results( res, id )
        url = res.effective_url
        log_issue(
            :var          => 'n/a',
            :url          => url,
            :injected     => id,
            :id           => id,
            :regexp       => 'n/a',
            :regexp_match => 'n/a',
            :elem         => Issue::Element::PATH,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        )

        # inform the user that we have a match
        print_ok( "Match at #{url}" )
        print_verbose( "Injected string: #{id}" )
    end


end
end
end
