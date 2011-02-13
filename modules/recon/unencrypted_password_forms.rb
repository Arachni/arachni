=begin
  $Id$

                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# Unencrypted password form
#
# Looks for password inputs that don't submit data over an encrypted channel (HTTPS).
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
# @see http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection
#
class UnencryptedPasswordForms < Arachni::Module::Base

    def initialize( page )
        # in this case we don't need to call the parent
        @page = page

        @results    = []
        @@__audited ||= Set.new
    end

    def run( )

        @page.forms.each {
            |form|
            __check( form )
        }

        # register our results with the system
        register_results( @results )
    end

    def __check( form )

        scheme = URI( form.action ).scheme
        return if( scheme.downcase == 'https' )

        form.raw['auditable'].each {
            |input|

            next if !input['type']

            if( input['type'].downcase == 'password' )
                __log( form.url, input )
            end
        }
    end

    def __log( url, input )

        if @@__audited.include?( input['name'] )
            print_info( 'Skipping already audited field \'' +
                input['name'] + '\' of url: ' + url )
            return
        end

        name = input['name'] || input['id'] || 'n/a'
        @@__audited << name

        # append the result to the results array
        @results << Issue.new( {
            :var          => name,
            :url          => url,
            :elem         => Issue::Element::FORM,
            :response     => @page.html,
        }.merge( self.class.info ) )

        print_ok( "Found unprotected password field '#{input['name']}' at #{url}" )

    end

    def self.info
        {
            :name           => 'UnencryptedPasswordForms',
            :description    => %q{Looks for password inputs that don't submit data
                over an encrypted channel (HTTPS).},
            :elements       => [
                Issue::Element::FORM
            ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com> ',
            :version        => '0.1',
            :references     => {
                'OWASP Top 10 2010' => 'http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection'
            },
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Unencrypted password form.},
                :description => %q{Transmission of password does not use an encrypted channel.},
                :tags        => [ 'unencrypted', 'password', 'form' ],
                :cwe         => '319',
                :severity    => Issue::Severity::MEDIUM,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

end
end
end
