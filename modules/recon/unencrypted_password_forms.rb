=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules
module Recon
  
#
# Unencrypted password form
#
# Looks for password inputs that don't submit data over an encrypted channel (HTTPS).
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
# @see http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection
#
class UnencryptedPasswordForms < Arachni::Module::Base

    include Arachni::Module::Registrar

    def initialize( page )
        # in this case we don't need to call the parent
        @page = page
        
        @results    = []
        @@__audited ||= []
    end
    
    def run( )
        
        get_forms.each {
            |form|
            __check( form )
        }
        
        # register our results with the system
        register_results( @results )
    end
    
    def __check( form )
        
        scheme = URI( form['attrs']['action'] ).scheme
        return if( scheme.downcase == 'https' )
        
        form['auditable'].each {
            |input|
            
            next if !input['type']
            
            if( input['type'].downcase == 'password' )
                __log( form['attrs']['action'], input )
            end
        }
    end
    
    def __log( url, input )
        
        if @@__audited.include?( input['name'] )
            print_info( 'Skipping already audited field \'' +
                input['name'] + '\' of url: ' + url )
            return
        end
        
        @@__audited << input['name']
      
        # append the result to the results array
        @results << Vulnerability.new( {
            :var          => input['name'],
            :url          => url,
            :injected     => 'n/a',
            :id           => 'n/a',
            :regexp       => 'n/a',
            :regexp_match => 'n/a',
            :elem         => Vulnerability::Element::FORM,
            :response     => @page.html,
            :headers      => {
                :request    => 'n/a',
                :response   => 'n/a',    
            }
        }.merge( self.class.info ) )
        
        print_ok( "Found unprotected password field '#{input['name']}' at #{url}" )

    end
    
    def self.info
        {
            :name           => 'UnencryptedPasswordForms',
            :description    => %q{Looks for password inputs that don't submit data
                over an encrypted channel (HTTPS).},
            :elements       => [
                Vulnerability::Element::FORM
            ],
            :author         => 'zapotek',
            :version        => '0.1',
            :references     => {
                'OWASP Top 10 2010' => 'http://www.owasp.org/index.php/Top_10_2010-A9-Insufficient_Transport_Layer_Protection'
            },
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{Unencrypted password form.},
                :description => %q{Transmission of password does not use an encrypted channel.},
                :cwe         => '319',
                :severity    => Vulnerability::Severity::MEDIUM,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end
    
end
end
end
end
