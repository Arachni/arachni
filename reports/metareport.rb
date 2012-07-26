=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

require Arachni::Options.instance.dir['reports'] + 'metareport/arachni_metareport.rb'

#
# Metareport
#
# Creates a file to be used with the Arachni MSF plug-in.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.1
#
class Arachni::Reports::Metareport < Arachni::Report::Base

    def run
        print_info 'Apologies, the metareport is currently out of commission.'
        return

        print_line
        print_status 'Creating file for the Metasploit framework...'

        msf = []
        auditstore.issues.each do |issue|
            next if !issue.metasploitable

            issue.variations.each do |variation|
                url = if ( method = issue.method.dup ) != 'post'
                    variation['url'].gsub( /\?.*/, '' )
                else
                    variation['url']
                end

                method = issue.elem if issue.elem == 'cookie' || issue.elem == 'header'

                # pp issue
                # pp variation['opts']

                params = variation['opts'][:combo]
                next if !params[issue.var]
                params[issue.var] = params[issue.var].gsub( variation['opts'][:injected_orig], 'XXinjectionXX' )

                if method == 'cookie'
                    params[issue.var] = URI.encode( params[issue.var], ';' )
                    cookies = sub_cookie( variation['headers']['request']['cookie'], params )
                    variation['headers']['request']['cookie'] = cookies.dup
                end

                # ap sub_cookie( variation['headers']['request']['cookie'], params )

                uri = URI( url )
                msf << ArachniMetareport.new(
                    host:        uri.host,
                    port:        uri.port,
                    vhost:       '',
                    ssl:         uri.scheme == 'https',
                    path:        uri.path,
                    query:       uri.query,
                    method:      method.upcase,
                    params:      params,
                    headers:     variation['headers']['request'].dup,
                    pname:       issue.var,
                    proof:       variation['regexp_match'],
                    risk:        '',
                    name:        issue.name,
                    description: issue.description,
                    category:    'n/a',
                    exploit:     issue.metasploitable
                )
            end
        end

        # pp msf

        File.open( outfile, 'w' ) { |f| ::YAML.dump( msf, outfile ) }

        print_status "Saved in '#{outfile}'."
    end

    def sub_cookie( str, params )
        hash = {}
        str.split( ';' ).each do |cookie|
            k, v = cookie.split( '=', 2 )
            hash[k] = v
        end

        hash.merge( params ).map{ |k,v| "#{k}=#{v}" }.join( ';' )
    end

    def self.info
        {
            name:        'Metareport',
            description: %q{Creates a file to be used with the Arachni MSF plug-in.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.1',
            options:     [ Options.outfile( '.msf' ) ]

        }
    end

end
