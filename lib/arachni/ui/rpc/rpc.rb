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

module Arachni

require Options.instance.dir['lib'] + 'rpc/client/dispatcher'
require Options.instance.dir['lib'] + 'rpc/client/instance'

require Options.instance.dir['lib'] + 'utilities'
require Options.instance.dir['lib'] + 'ui/cli/output'
require Options.instance.dir['lib'] + 'framework'

module UI

#
# Provides an self sufficient Arachni RPC client.
#
# It mimics the standard CLI interface's functionality
# albeit in a client-server fashion.
#
# This should be your first stop when looking into creating your own RPC client. <br/>
# Of course you don't need to instantiate the framework or any other Arachni related classes
# in your own client, this is just to provide some other info to the user.
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class RPC
    include Arachni::UI::Output
    include Arachni::Utilities

    def initialize( opts )

        @opts = opts

        # if we have a load profile load it and merge it with the
        # user supplied options
        if( @opts.load_profile )
            load_profile( @opts.load_profile )
        end

        debug if @opts.debug

        # we don't need the framework for much,
        # in this case only for report generation, version number etc.
        @framework = Arachni::Framework.new( @opts )

        # print banner message
        banner

        # if the user needs help, output it and exit
        if opts.help
            usage
            exit 0
        end

        # if the user wants to see the available reports, output them and exit
        if !opts.lsrep.empty?
            lsrep
            exit
        end

        if opts.show_profile
            print_profile( )
            exit 0
        end

        if opts.save_profile
            exception_jail{ save_profile( opts.save_profile ) }
            exit 0
        end


        # Check for missing url
        if !@opts.url && @opts.lsmod.empty?
            print_bad( "Missing url argument." )
            exit 0
        end

        begin

            @dispatcher = Arachni::RPC::Client::Dispatcher.new( @opts, @opts.server )

            # get a new instance and assign the url we're going to audit as the
            # 'owner'
            @instance = @dispatcher.dispatch( @opts.url.to_s )

            # start the RPC client
            @server = Arachni::RPC::Client::Instance.new( @opts, @instance['url'], @instance['token'] )
        rescue Exception => e
            print_error( "Could not connect to server." )
            print_debug( "Error: #{e.to_s}." )
            print_debug_backtrace( e )
            exit 0
        end

        # if the user wants to see the available reports, output them and exit
        if !opts.lsplug.empty?
            lsplug( @server.framework.lsplug )
            shutdown
            exit
        end

        # if the user wants to see the available modules
        # grab them from the server, output them, exit and shutdown the server.
        if !opts.lsmod.empty?
            lsmod( @server.framework.lsmod )
            shutdown
            exit
        end

        #
        # we could just execute pause() upon an interrupt but RPC I/O
        # needs to be synchronized otherwise we'll get an HTTP exception
        #
        @pause = false
        trap( 'INT' ){ @pause = true }

        begin
            parse_opts
        rescue Exception => e
            print_error( 'Error: ' + e.to_s )
            print_debug_backtrace( e )
            begin
                shutdown
            rescue
            end
            exit
        end
    end

    def run

        exception_jail {
            print_status 'Running framework...'
            @server.framework.run

            print_line

            # grab the RPC server output while a scan is running
            while @server.framework.busy?
                output

                pause if @pause

                # things will get crazy if we don't block a bit I think...
                # we'll see...
                ::IO::select( nil, nil, nil, 2 )
            end

            puts
        }

        report
        shutdown
    end

    private

    #
    # Loads an Arachni Framework Profile file and merges it with the
    # user supplied options.
    #
    # @param    [Array<String>]    profiles    the files to load
    #
    def load_profile( profiles )
        exception_jail{
            @opts.load_profile = nil
            profiles.each {
                |filename|
                @opts.merge!( Arachni::Options.instance.load( filename ) )
            }
        }
    end

    #
    # Saves options to an Arachni Framework Profile file.<br/>
    # The file will be appended with the {PROFILE_EXT} extension.
    #
    # @param    [String]    filename
    #
    def save_profile( filename )

        if filename = @opts.save( filename )
            print_status( "Saved profile in '#{filename}'." )
            print_line( )
        else
            banner( )
            print_error( 'Could not save profile.' )
            exit 0
        end
    end

    #
    # Grabs the output from the RPC server and routes it to the proper output method.
    #
    def output
        @server.service.output.each {
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

    #
    # Handles Ctrl+C interrupts
    #
    # Once an interrupt has been trapped the system pauses and waits
    # for user input. <br/>
    # The user can either continue or exit.
    #
    # The interrupt will be handled after a module has finished.
    #
    def pause( )

        print_status( 'Paused...' )
        @server.framework.pause

        print_line
        print_info( 'Results thus far:' )

        #
        # make it easier on the user, grab the report to have something
        # to show him while the scan is paused.
        #

        begin
            print_issues( @server.framework.issues )
        rescue Exception => e
            exception_jail{ raise e }
            exit 0
        end

        print_info( 'Arachni is paused, do you want to continue?' )

        print_info( 'Continue? (hit \'enter\' to continue, \'e\' to exit)' )

        if gets[0] == 'e'
            print_status( 'Aborting scan...' )
            @server.framework.clean_up
            report
            shutdown
            print_info( 'Exiting...' )
            exit 0
        end

        @pause = false
        @server.framework.resume
    end

    #
    # Laconically output the discovered issues
    #
    # This method is used during a pause.
    #
    def print_issues( issues )

        print_line
        print_info( issues.size.to_s + ' issues have been detected.' )

        print_line
        issues.each {
            |issue|

            print_ok( "#{issue.name} (In #{issue.elem} variable '#{issue.var}'" +
              " - Severity: #{issue.severity}" )
        }

        print_line
    end

    #
    # Parses, sets and sends options to the RPC server.
    #
    def parse_opts
        @opts.reports['stdout'] = {} if @opts.reports.empty?

        #
        # No modules have been specified, set the mods to '*' (all).
        #
        if( !@opts.mods || @opts.mods.empty? )
            print_info( "No modules were specified." )
            print_info( " -> Will run all mods." )

            @opts.mods = ['*']
        end

        #
        # The user hasn't selected any elements to audit, set it to audit links, forms and cookies.
        #
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

        opts = @opts.to_h.dup

        @framework.reports.load( opts['reports'].keys )

        # do not send these options over the wire
        [
            # this is bad, do not override the server's directory structure
            'dir',

            # this is of no use to the server is a local option for this UI
            'server',

            # profiles are not to be sent over the wire
            'load_profile',

            # report options should remain local
            'repopts',
            'repsave',

            # do not automatically send this options over
            # we'll take care of this ourselves as soon as we get to the 'cookie_jar'
            # option.
            'cookies',
            'rpc_instance_port_range',
            'datastore',
            'reports'
        ].each {
            |k|
            opts.delete( k )
        }

        opts['url'] = opts['url'].to_s

        if opts['cookie_jar']
            opts['cookies'] = parse_cookie_jar( opts['cookie_jar'] )
            opts.delete( 'cookie_jar' )
        end

        @framework.plugins.load_defaults.each {
            |plugin|
            @opts.plugins[plugin] = {} if !@opts.plugins.include?( plugin )
        }

        @server.plugins.load( @opts.plugins )
        @server.modules.load( @opts.mods )
        @server.opts.set( opts )

        # ap opts
        # exit
    end

    #
    # Remote kill-switch, shuts down the server
    #
    def shutdown
        print_status "Shutting down the server..."
        @server.service.shutdown
    end

    #
    # Grabs the report from the RPC server and runs the selected Arachni report module.
    #
    def report
        print_status "Grabbing scan report..."

        # this will return the AuditStore as a string in YAML format
        audit_store = @server.framework.auditstore

        # run the loaded reports and get the generated filename
        @framework.reports.run( audit_store )

        print_status "Grabbing stats..."

        stats = @server.framework.stats

        print_line
        print_info( "Sent #{stats[:requests]} requests." )
        print_info( "Received and analyzed #{stats[:responses]} responses." )
        print_info( 'In ' + stats[:time].to_s )

        avg = 'Average: ' + stats[:avg].to_s + ' requests/second.'
        print_info( avg )

        print_line
    end

    def parse_cookie_jar( jar )
        # make sure that the provided cookie-jar file exists
        if !File.exist?( jar )
            raise( Arachni::Exceptions::NoCookieJar,
                'Cookie-jar \'' + jar + '\' doesn\'t exist.' )
        end

        Arachni::Element::Cookie.from_file( @opts.url.to_s, jar ).inject({}) do |h, e|
            h.merge!( e.simple ); h
        end
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

            print_status( "#{info[:mod_name]}:" )
            print_line( "--------------------" )

            print_line( "Name:\t\t"       + info[:name] )
            print_line( "Description:\t"  + info[:description] )

            if( info[:elements] && info[:elements].size > 0 )
                print_line( "Elements:\t" +
                    info[:elements].join( ', ' ).downcase )
            end

            if( info[:dependencies] )
                print_line( "Dependencies:\t" +
                    info[:dependencies].join( ', ' ).downcase )
            end

            print_line( "Author:\t\t"     + info[:author].join( ", " ) )
            print_line( "Version:\t"      + info[:version] )

            print_line( "References:" )
            if info[:references].is_a?( Hash )
                info[:references].keys.each {
                    |key|
                    print_info( key + "\t\t" + info[:references][key] )
                }
            end

            print_line( "Targets:" )
            if info[:targets]
                print_line( "Targets:" )

                if info[:targets].is_a?( Hash )
                    info[:targets].keys.each do |key|
                        print_info( key + "\t\t" + info[:targets][key] )
                    end
                else
                    info[:targets].each do |target|
                        print_info( target )
                    end
                end
            end

            if( info[:issue] &&
                ( sploit = info[:issue]['metasploitable'] ) )
                print_line( "Metasploitable:\t" + sploit )
            end

            print_line( "Path:\t"    + info[:path] )

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

                info[:options].each {
                    |option|
                    print_info( "\t#{option.name} - #{option.desc}" )
                    print_info( "\tType:        #{option.type}" )
                    print_info( "\tDefault:     #{option.default}" )
                    print_info( "\tRequired?:   #{option.required?}" )

                    print_line( )
                }
            end

            print_line( "Author:\t\t"     + info[:author].join( ", " ) )
            print_line( "Version:\t"      + info[:version] )
            print_line( "Path:\t"         + info[:path] )

            i+=1

            print_line
        }

    end

    #
    # Outputs all available reports and their info.
    #
    def lsplug( plugins )
        print_line
        print_line
        print_info( 'Available plugins:' )
        print_line

        plugins.each {
            |info|

            print_status( "#{info[:plug_name]}:" )
            print_line( "--------------------" )

            print_line( "Name:\t\t"       + info[:name] )
            print_line( "Description:\t"  + info[:description] )

            if( info[:options] && !info[:options].empty? )
                print_line( "Options:\t" )

                info[:options].each {
                    |option|
                    print_info( "\t#{option['name']} - #{option['desc']}" )
                    print_info( "\tType:        #{option['type']}" )
                    print_info( "\tDefault:     #{option['default']}" )
                    print_info( "\tRequired?:   #{option['required']}" )

                    print_line( )
                }
            end

            print_line( "Author:\t\t"     + info[:author].join( ", " ) )
            print_line( "Version:\t"      + info[:version] )
            print_line( "Path:\t"         + info[:path] )

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
        print_line BANNER
        print_line
        print_line
    end

    def print_profile( )
        print_info( 'Running profile:' )
        print_info( @opts.to_args )
    end

    #
    # Outputs help/usage information.<br/>
    # Displays supported options and parameters.
    #
    # @return [void]
    #
    def usage
        print_line <<USAGE
  Usage:  arachni_rpc --server https://host:port \[options\] url

  Supported options:


    SSL --------------------------
    (Do *not* use encrypted keys!)

    --ssl-pkey   <file>         location of the SSL private key (.pem)
                                    (Used to verify the the client to the servers.)

    --ssl-cert   <file>         location of the SSL certificate (.pem)
                                    (Used to verify the the client to the servers.)

    --ssl-ca     <file>         location of the CA certificate (.pem)
                                    (Used to verify the servers to the client.)


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

    --cookie-jar=<cookiejar>    netscape HTTP cookie file, use curl to create it


    --user-agent=<user agent>   specify user agent

    --authed-by=<who>           who authorized the scan, include name and e-mail address
                                  (It'll make it easier on the sys-admins during log reviews.)
                                  (Will be appended to the user-agent string.)


    Profiles -----------------------

    --save-profile=<file>       save the current run profile/options to <file>

    --load-profile=<file>       load a run profile from <file>
                                  (Can be used multiple times.)
                                  (You can complement it with more options, except for:
                                      * --mods
                                      * --redundant)

    --show-profile              will output the running profile as CLI arguments


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

    --spider-first              spider first, audit later


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
                                  (Modules are referenced by their filename without the '.rb' extension, use '--lsmod' to see all.
                                  Use '*' as a module name to deploy all modules or inside module names like so:
                                      xss_*   to load all xss modules
                                      sqli_*  to load all sql injection modules
                                      etc.

                                   You can exclude modules by prefixing their name with a dash:
                                      --mods=*,-backup_files,-xss
                                   The above will load all modules except for the 'backup_files' and 'xss' modules.

                                   Or mix and match:
                                      -xss_*   to unload all xss modules. )


    Reports ------------------------

    --lsrep                       list available reports

    --repload=<file>              load audit results from an .afr file
                                    (Allows you to create new reports from finished scans.)

    --report='<report>:<optname>=<val>,<optname2>=<val2>,...'

                                  <report>: the name of the report as displayed by '--lsrep'
                                    (Reports are referenced by their filename without the '.rb' extension, use '--lsrep' to see all.)
                                    (Default: stdout)
                                    (Can be used multiple times.)


    Plugins ------------------------

    --lsplug                      list available plugins

    --plugin='<plugin>:<optname>=<val>,<optname2>=<val2>,...'

                                  <plugin>: the name of the plugin as displayed by '--lsplug'
                                    (Plugins are referenced by their filename without the '.rb' extension, use '--lsplug' to see all.)
                                    (Can be used multiple times.)

USAGE
    end

end

end
end
