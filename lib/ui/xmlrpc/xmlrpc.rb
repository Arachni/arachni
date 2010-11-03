require 'xmlrpc/client'
require 'openssl'

module Arachni

require Options.instance.dir['lib'] + 'module/utilities'
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
    include Arachni::Module::Utilities

    def initialize( opts )

        @opts = opts

        banner

        if opts.help
            usage
            exit 0
        end

        @server = ::XMLRPC::Client.new2( @opts.server )
        @server.timeout = 9999999

        @server.instance_variable_get( :@http ).
            instance_variable_set( :@verify_mode, OpenSSL::SSL::VERIFY_NONE )

        #begin
            parse_opts
        #rescue Exception => e
        #    print_error e.inspect
        #    print_debug_backtrace( e )
        #    reset
        #    exit
        #end
    end

    def run

        exception_jail {
            print_status 'Running framework:'
            ap @server.call( "framework.run" )

            print_line
            while( @server.call( "framework.busy?" ) )
                output
                sleep( 1 )
            end

            puts
            report
        }

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

        # do not send these options over the wire
        illegal =[
            'dir',
            'server',
            'reports',
            'repopts',
            'load_profile'
        ]

        @opts.to_h.each {
            |opt, arg|

            next if !arg
            next if illegal.include? opt

            case opt

            when "lsmod"
                next if !arg || arg.empty?
                print_status 'lsmod:'
                ap @server.call( "framework.lsmod" )
                reset
                exit

            when "debug"
                print_status "Enabling #{opt}:"
                ap @server.call( "framework.debug_on" )
                debug!

            when "arachni_verbose"
                print_status "Enabling #{opt}:"
                ap @server.call( "framework.verbose_on" )
                verbose!

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

            else
                print_status "Enabling #{opt}:"
                ap @server.call( "opts.#{opt}=", arg )

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

        print_status "Grabbing stats..."
        ap @server.call( "framework.stats" )
    end

    #
    # Outputs Arachni banner.<br/>
    # Displays version number, revision number, author details etc.
    #
    # @see VERSION
    # @see REVISION
    #
    # @return [void]
    #
    def banner
        require @opts.dir['lib'] + 'framework'
        framework = Arachni::Framework.new( @opts )

        print_line 'Arachni - Web Application Security Scanner Framework v' +
            framework.version + ' [' + framework.revision + ']
       Author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
                                      <zapotek@segfault.gr>
               (With the support of the community and the Arachni Team.)

       Website:       http://github.com/Zapotek/arachni
       Documentation: http://github.com/Zapotek/arachni/wiki'
        framework = nil
        print_line
        print_line

    end

    #
    # Outputs help/usage information.<br/>
    # Displays supported options and parameters.
    #
    # @return [void]
    #
    def usage
        print_line <<USAGE
  Usage:  arachni --server http[s]://host:port/ \[options\] url

  Supported options:


    General ----------------------

    -h
    --help                      output this

    -v                          be verbose

    --debug                     show what is happening internally
                                  (You should give it a shot sometime ;) )

    --only-positives            echo positive results *only*

    --http-req-limit            concurent HTTP requests limit
                                  (Be carefull not to kill your server.)
                                  (Default: 60)
                                  (*NOTE*: If your scan seems unresponsive try lowering the limit.)

    --http-harvest-last         build up the HTTP request queue of the audit for the whole site
                                 and harvest the HTTP responses at the end of the crawl.
                                 (In some test cases this option has split the scan time in half.)
                                 (Default: responses will be harvested for each page)
                                 (*NOTE*: If you are scanning a high-end server and
                                   you are using a powerful machine with enough bandwidth
                                   *and* you feel dangerous you can use
                                   this flag with an increased '--http-req-limit'
                                   to get maximum performance out of your scan.)
                                 (*WARNING*: When scanning large websites with hundreads
                                  of pages this could eat up all your memory pretty quickly.)

    --cookie-jar=<cookiejar>    netscape HTTP cookie file, use curl to create it


    --user-agent=<user agent>   specify user agent

    --authed-by=<who>           who authorized the scan, include name and e-mail address
                                  (It'll make it easier on the sys-admins during log reviews.)
                                  (Will be appended to the user-agent string.)

    Crawler -----------------------

    -e <regex>
    --exclude=<regex>           exclude urls matching regex
                                  (Can be used multiple times.)

    -i <regex>
    --include=<regex>           include urls matching this regex only
                                  (Can be used multiple times.)

    --redundant=<regex>:<count> limit crawl on redundant pages like galleries or catalogs
                                  (URLs matching <regex> will be crawled <count> links deep.)
                                  (Can be used multiple times.)

    -f
    --follow-subdomains         follow links to subdomains (default: off)

    --obey-robots-txt           obey robots.txt file (default: off)

    --depth=<number>            depth limit (default: inf)
                                  (How deep Arachni should go into the site structure.)

    --link-count=<number>       how many links to follow (default: inf)

    --redirect-limit=<number>   how many redirects to follow (default: inf)


    Auditor ------------------------

    -g
    --audit-links               audit link variables (GET)

    -p
    --audit-forms               audit form variables
                                  (usually POST, can also be GET)

    -c
    --audit-cookies             audit cookies (COOKIE)

    --exclude-cookie=<name>     cookies not to audit
                                  (You should exclude session cookies.)
                                  (Can be used multiple times.)

    --audit-headers             audit HTTP headers
                                  (*NOTE*: Header audits use brute force.
                                   Almost all valid HTTP request headers will be audited
                                   even if there's no indication that the web app uses them.)
                                  (*WARNING*: Enabling this option will result in increased requests,
                                   maybe by an order of magnitude.)


    Modules ------------------------

    --lsmod=<regexp>            list available modules based on the provided regular expression
                                  (If no regexp is provided all modules will be listed.)
                                  (Can be used multiple times.)


    -m <modname,modname..>
    --mods=<modname,modname..>  comma separated list of modules to deploy
                                  (Use '*' to deploy all modules)
                                  (You can exclude modules by prefixing their name with a dash:
                                      --mods=*,-backup_files,-xss
                                   The above will load all modules except for the 'backup_files' and 'xss' modules. )

USAGE
    end

end

end
end
