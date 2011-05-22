=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

require Options.instance.dir['reports'] + 'metareport/arachni_metareport.rb'

module Reports

#
# Metareport
#
# Creates a file to be used with the Arachni MSF plug-in.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Metareport < Arachni::Report::Base

    #
    # @param [AuditStore]  audit_store
    # @param [Hash]        options    options passed to the report
    #
    def initialize( audit_store, options )
        @audit_store = audit_store
        @options     = options
    end

    def run( )

        print_line( )
        print_status( 'Creating file for the Metasploit framework...' )

        msf = []

        @audit_store.issues.each {
            |issue|
            next if !issue.metasploitable

            issue.variations.each {
                |variation|

                if( ( method = issue.method.dup ) != 'post' )
                    url = variation['url'].gsub( /\?.*/, '' )
                else
                    url = variation['url']
                end

                if( issue.elem == 'cookie' || issue.elem == 'header' )
                    method = issue.elem
                end

                # pp issue
                # pp variation['opts']

                params = variation['opts'][:combo]
                params[issue.var] = params[issue.var].gsub( variation['opts'][:injected_orig], 'XXinjectionXX' )

                if method == 'cookie'
                    params[issue.var] = URI.encode( params[issue.var], ';' )
                    cookies = sub_cookie( variation['headers']['request']['cookie'], params )
                    variation['headers']['request']['cookie'] = cookies.dup
                end

                # ap sub_cookie( variation['headers']['request']['cookie'], params )

                msf << ArachniMetareport.new( {
                    :host   => URI( url ).host,
                    :port   => URI( url ).port,
                    :vhost  => '',
                    :ssl    => URI( url ).scheme == 'https',
                    :path   => URI( url ).path,
                    :query  => URI( url ).query,
                    :method => method.upcase,
                    :params => params,
                    :headers=> variation['headers']['request'].dup,
                    :pname  => issue.var,
                    :proof  => variation['regexp_match'],
                    :risk   => '',
                    :name   => issue.name,
                    :description    =>  issue.description,
                    :category   =>  'n/a',
                    :exploit    => issue.metasploitable
                } )
            }

        }

        # pp msf

        outfile = File.new( @options['outfile'], 'w')
        YAML.dump( msf, outfile )
        outfile.close

        print_status( 'Saved in \'' + @options['outfile'] + '\'.' )
    end

    def sub_cookie( str, params )
        hash = {}
        str.split( ';' ).each {
            |cookie|
            k,v = cookie.split( '=', 2 )
            hash[k] = v
        }

        return hash.merge( params ).map{ |k,v| "#{k}=#{v}" }.join( ';' )
    end

    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            :name           => 'Metareport',
            :description    => %q{Creates a file to be used with the Arachni MSF plug-in.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptString.new( 'outfile', [ false, 'Where to save the report.',
                    Time.now.to_s + '.msf' ] ),
            ]

        }
    end

end

end
end
