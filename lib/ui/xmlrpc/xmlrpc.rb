require 'xmlrpc/client'
require 'openssl'

module Arachni

require Options.instance.dir['lib'] + 'module/utilities'
require Options.instance.dir['lib'] + 'ui/cli/output'
require Options.instance.dir['lib'] + 'framework'
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

        # we don't need the framework for much, in this case only for report generation
        @framework = Arachni::Framework.new( @opts )

        # print bannger message
        banner

        # if user needs help output it and exit
        if opts.help
            usage
            exit 0
        end

        # if user wants to se the available reports output them and exit
        if opts.lsrep
            lsrep
            exit
        end

        @server = ::XMLRPC::Client.new2( @opts.server )

        # there'll we a HELL of lot of output so things might get..laggy.
        # a big timeout is required to avoid Timeout exceptions...
        @server.timeout = 9999999

        # a little black magic to disable cert verification
        @server.instance_variable_get( :@http ).
            instance_variable_set( :@verify_mode, OpenSSL::SSL::VERIFY_NONE )

        # if user wants to se the available modules
        # grab them from the server, output them, exit and reset the server.
        # not 100% sure that we need to reset but better to be safe than sorry.
        if !opts.lsmod.empty?
            lsmod( @server.call( "framework.lsmod" ) )
            reset
            exit
        end

        trap( 'INT' ){ pause }

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
            print_status 'Running framework...'
            @server.call( "framework.run" )

            print_line

            while( @server.call( "framework.busy?" ) )
                output

                # things will get crazy if we don't block for a second or so...
                ::IO::select( nil, nil, nil, 1 )
            end

            puts
            report
        }

        # ensure that the framework will be reset
        reset
    end

    def pause
        @server.call( "framework.pause" )
        print_status( 'Paused...' )
        gets
        @server.call( "framework.resume" )
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

        if( !@opts.mods || @opts.mods.empty? )
            print_info( "No modules were specified." )
            print_info( " -> Will run all mods." )

            @opts.mods = ['*']
        end

        if( !@opts.audit_links &&
            !@opts.audit_forms &&
            !@opts.audit_cookies &&
            !@opts.audit_headers
            )
            print_info( "No audit options were specified." )
            print_info( " -> Will audit links, forms and cookies." )

            @opts.audit_links   = true
            @opts.audit_forms   = true
            @opts.audit_cookies = true
        end

        # do not send these options over the wire
        illegal =[
            'dir',
            'server',
            'load_profile',
            'repopts',
            'repsave'
        ]

        @opts.to_h.each {
            |opt, arg|

            next if !arg
            next if illegal.include? opt

            case opt

            when "debug"
                print_status "Enabling debugging mode."
                @server.call( "framework.debug_on" )
                debug!

            when "arachni_verbose"
                print_status "Enabling verbosity."
                @server.call( "framework.verbose_on" )
                verbose!

            when 'redundant'
                print_status 'Setting redundancy rules.'

                redundant = []
                arg.each {
                    |rule|
                    rule['regexp'] = rule['regexp'].to_s
                    redundant << rule
                }
                @server.call( "opts.redundant=", redundant )

            when 'exclude', 'include'
                print_status "Setting #{opt} rules."
                @server.call( "opts.#{opt}=", arg.map{ |rule| rule.to_s } )

            when 'url'
                print_status 'Setting url: ' + @server.call( "opts.url=", arg.to_s )

            when 'cookies'
                print_status 'Setting cookies:'
                cookies = {}
                arg.split( ';' ).each {
                    |cookie|
                    k,v = cookie.split( '=', 2 )
                    cookies[k.strip] = v.strip
                }

                @server.call( "opts.cookies=", cookies )

            when 'mods'
                print_status 'Loading modules:'
                @server.call( "modules.load", arg ).each {
                    |mod|
                    print_info ' * ' + mod
                }

            when "http_req_limit"
                print_status 'Setting HTTP request limit: ' +
                    @server.call( "opts.http_req_limit=", arg ).to_s

            when 'reports'
                arg << 'stdout'
                exception_jail{ @framework.reports.load( arg ) }

            else
                print_status "Setting #{opt}."
                @server.call( "opts.#{opt}=", arg )

            end
        }

    end

    def shutdown
        print_status "Shutting down the server..."
        @server.call( "service.shutdown" )
    end

    def reset
        print_status "Resetting the server..."
        @server.call( "service.reset" )
    end

    def report
        print_status "Grabbing scan report..."

        # this will return the AuditStore as a hash
        # ap @server.call( "framework.report" )

        # this will return the AuditStore as a string in YAML format
        audit_store = YAML.load( @server.call( "framework.auditstore" ) )

        filename = @framework.reports.run( audit_store )

        if !filename
            filename = URI.parse( audit_store.options['url'] ).host +
                        '-' + Time.now.to_s
        end

        filename += @framework.reports.extension

        print_status( 'Dumping audit results in \'' + filename  + '\'.' )
        audit_store.save( filename  )

        print_status( 'Done!' )

        print_status "Grabbing stats..."

        stats = @server.call( "framework.stats" )
        print_line
        print_info( "Sent #{stats['requests']} requests." )
        print_info( "Received and analyzed #{stats['responses']} responses." )
        print_info( 'In ' + stats['time'] )

        avg = 'Average: ' + stats['avg'] + ' requests/second.'
        print_info( avg )

        print_line

    end

    #
    # Outputs all available modules and their info.
    #
    def lsmod( mods )

        i = 0
        print_info( 'Available modules:' )
        print_line

        mods.each {
            |info|

            print_status( "#{info['mod_name']}:" )
            print_line( "--------------------" )

            print_line( "Name:\t\t"       + info['name'] )
            print_line( "Description:\t"  + info['description'] )

            if( info['elements'] && info['elements'].size > 0 )
                print_line( "HTML Elements:\t" +
                    info['elements'].join( ', ' ).downcase )
            end

            if( info['dependencies'] )
                print_line( "Dependencies:\t" +
                    info['dependencies'].join( ', ' ).downcase )
            end

            print_line( "Author:\t\t"     + info['author'] )
            print_line( "Version:\t"      + info['version'] )

            print_line( "References:" )
            info['references'].keys.each {
                |key|
                print_info( key + "\t\t" + info['references'][key] )
            }

            print_line( "Targets:" )
            info['targets'].keys.each {
                |key|
                print_info( key + "\t\t" + info['targets'][key] )
            }

            if( info['vulnerability'] &&
                ( sploit = info['vulnerability']['metasploitable'] ) )
                print_line( "Metasploitable:\t" + sploit )
            end

            print_line( "Path:\t"    + info['path'] )

            i+=1

            # pause every 3 modules to give the user time to read
            # (cheers to aungkhant@yehg.net for suggesting it)
            if( i % 3 == 0 && i != mods.size )
                print_line
                print_line( 'Hit <space> <enter> to continue, any other key to exit. ' )

                if gets[0] != " "
                    print_line
                    return
                end

            end

            print_line
        }

    end

    #
    # Outputs all available reports and their info.
    #
    def lsrep
        i = 0
        print_info( 'Available reports:' )
        print_line

        @framework.lsrep().each {
            |info|

            print_status( "#{info[:rep_name]}:" )
            print_line( "--------------------" )

            print_line( "Name:\t\t"       + info[:name] )
            print_line( "Description:\t"  + info[:description] )

            if( info[:options] && info[:options].size > 0 )
                print_line( "Options:\t" )

                info[:options].each_pair {
                    |option, info|
                    print_info( "\t#{option} - #{info[1]}" )
                    print_info( "\tValues: #{info[0]}" )

                    print_line( )
                }
            end

            print_line( "Author:\t\t"     + info[:author] )
            print_line( "Version:\t"      + info[:version] )
            print_line( "Path:\t"         + info[:path] )

            i+=1

            print_line
        }

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
        print_line 'Arachni - Web Application Security Scanner Framework v' +
            @framework.version + ' [' + @framework.revision + ']
       Author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
                                      <zapotek@segfault.gr>
               (With the support of the community and the Arachni Team.)

       Website:       http://github.com/Zapotek/arachni
       Documentation: http://github.com/Zapotek/arachni/wiki'
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

    Reports ------------------------

    --lsrep                       list available reports

    --repsave=<file>              save the audit results in <file>
                                    (The file will be saved with an extention of: #{@framework.reports.extension})

    --repopts=<option1>:<value>,<option2>:<value>,...
                                  Set options for the selected reports.
                                    (One invocation only, options will be applied to all loaded reports.)

    --report=<repname>            <repname>: the name of the report as displayed by '--lsrep'
                                    (Default: stdout)
                                    (Can be used multiple times.)

USAGE
    end

end

end
end
