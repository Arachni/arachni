require 'xmlrpc/client'
require 'openssl'

module Arachni

require Options.instance.dir['lib'] + 'ui/cli/output'

module UI

#
# Arachni::UI:XMLRPC class
#
# Provides an Arachni XML-RPC client.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class XMLRPC

    include Arachni::UI::Output

    def initialize( opts )

        @opts = opts

        @server = ::XMLRPC::Client.new2( @opts.server )
        @server.timeout = 9999999

        @server.instance_variable_get( :@http ).
            instance_variable_set( :@verify_mode, OpenSSL::SSL::VERIFY_NONE )

        begin
            parse_opts
        rescue
            reset
            exit
        end
    end

    def run
        begin
            print_status 'Running framework:'
            ap @server.call( "framework.run" )

            print_line
            while( @server.call( "framework.busy?" ) )
                output
                sleep( 1 )
            end

            puts
            report
        rescue
        end

        # ensure that the framework will be reset
        reset
    end

    def output
        @server.call( "service.output" ).each {
            |out|
            type = out.keys[0]
            msg  = out.values[0]
            begin
                self.send( "print_#{type}", msg )
            rescue
                print_line( msg )
            end
        }
    end

    def parse_opts

        @opts.to_h.each {
            |opt, arg|

            next if !arg

            case opt
            when 'redundant'
                print_status 'Setting redundancy rules:'

                redundant = []
                arg.each {
                    |rule|
                    rule['regexp'] = rule['regexp'].to_s
                    redundant << rule
                }
                @server.call( "opts.redundant=", redundant )

            when 'exclude', 'include'
                print_status "Setting #{opt} rules:"
                ap @server.call( "opts.#{opt}=", arg.map{ |rule| rule.to_s } )

            when "audit_forms", "audit_links", "audit_cookies", "audit_headers",
                    "http_harvest_last"

                print_status "Enabling #{opt}:"
                ap @server.call( "opts.#{opt}=", true )

            when 'url'
                print_status 'Setting url:'
                ap @server.call( "opts.url=", arg.to_s )

            when 'cookies'
                print_status 'Setting cookies:'
                cookies = {}
                arg.split( ';' ).each {
                    |cookie|
                    k,v = cookie.split( '=', 2 )
                    cookies[k.strip] = v.strip
                }

                ap @server.call( "opts.cookies=", cookies )

            when 'mods'
                print_status 'Loading modules:'
                ap @server.call( "modules.load", arg )

            when "http_req_limit"
                print_status 'Setting HTTP request limit:'
                ap @server.call( "opts.http_req_limit=", arg )
            end
        }

    end

    def shutdown
        print_status "Shutting down..."
        ap @server.call( "service.shutdown" )
    end

    def reset
        print_status "Resetting..."
        @server.call( "service.reset" )
    end

    def report
        print_status "Grabbing scan report..."
        ap @server.call( "framework.report" )
    end

end

end
end
