=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

require Options.dir['lib']    + 'ui/cli/output'
require Options.dir['mixins'] + 'terminal'
require Options.dir['mixins'] + 'progress_bar'

module UI

#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @see Arachni::Framework::CLI
#
class CLI

module Utilities
    include Arachni::Utilities

    include Mixins::Terminal
    include Mixins::ProgressBar

    def print_issues( issues, unmute = false, &interceptor )
        interceptor ||= proc { |s| s }

        print_line( interceptor.call, unmute )
        print_info( interceptor.call( "#{issues.size} issues have been detected." ), unmute )

        print_line( interceptor.call, unmute )

        issue_cnt = issues.count
        issues.each.with_index do |issue, i|
            input = issue.var ? " input `#{issue.var}`" : ''
            meth  = issue.method ? " using #{issue.method}" : ''
            cnt   = "#{i + 1} |".rjust( issue_cnt.to_s.size + 2 )

            print_ok( interceptor.call(  "#{cnt} #{issue.name} at #{issue.url} in" +
                                  " #{issue.elem}#{input}#{meth}." ),
                      unmute
            )
        end

        print_line( interceptor.call, unmute )
    end

    #
    # Outputs all available modules and their info.
    #
    def lsplat( platforms )
        print_line
        print_line
        print_info 'Available platforms:'
        print_line

        i = 0
        platforms.each do |type, platforms|
            print_status "#{type}"

            platforms.each do |shortname, fullname|
                print_info "#{shortname}:\t\t#{fullname}"
            end

            print_line
        end

    end

    #
    # Outputs all available modules and their info.
    #
    def lsmod( modules )
        print_line
        print_line
        print_info 'Available modules:'
        print_line

        i = 0
        modules.each do |info|
            print_status "#{info[:mod_name]}:"
            print_line '--------------------'

            print_line "Name:\t\t#{info[:name]}"
            print_line "Description:\t#{info[:description]}"

            if info[:elements] && info[:elements].size > 0
                print_line "Elements:\t#{info[:elements].join( ', ' ).downcase}"
            end

            print_line "Author:\t\t#{info[:author].join( ", " )}"
            print_line "Version:\t#{info[:version]}"

            if info[:references]
                print_line 'References:'
                info[:references].keys.each do |key|
                    print_info "#{key}\t\t#{info[:references][key]}"
                end
            end

            if info[:targets]
                print_line 'Targets:'

                if info[:targets].is_a?( Hash )
                    info[:targets].keys.each do |key|
                        print_info "#{key}\t\t#{info[:targets][key]}"
                    end
                else
                    info[:targets].each { |target| print_info( target ) }
                end
            end

            if info[:issue] && sploit = info[:issue][:metasploitable]
                print_line "Metasploitable:\t#{sploit}"
            end

            print_line "Path:\t#{info[:path]}"

            i += 1

            # pause every 3 modules to give the user time to read
            # (cheers to aungkhant@yehg.net for suggesting it)
            if i % 3 == 0 && i != modules.size
                print_line
                print_line 'Hit <space> <enter> to continue, any other key to exit. '

                if gets[0] != ' '
                    print_line
                    return
                end

            end

            print_line
        end

    end

    #
    # Outputs all available reports and their info.
    #
    def lsrep( reports )
        print_line
        print_line
        print_info 'Available reports:'
        print_line

        reports.each do |info|
            print_status "#{info[:rep_name]}:"
            print_line '--------------------'

            print_line "Name:\t\t#{info[:name]}"
            print_line "Description:\t#{info[:description]}"

            if info[:options] && !info[:options].empty?
                print_line( "Options:\t" )

                info[:options].each do |option|
                    option = option.is_a?( Hash ) ? option : option.to_h

                    print_info "\t#{option['name']} - #{option['desc']}"
                    print_info "\tType:        #{option['type']}"
                    print_info "\tDefault:     #{option['default']}"
                    print_info "\tRequired?:   #{option['required?']}"

                    print_line
                end
            end

            print_line "Author:\t\t#{info[:author].join( ", " )}"
            print_line "Version:\t#{info[:version] }"
            print_line "Path:\t#{info[:path]}"

            print_line
        end
    end

    #
    # Outputs all available reports and their info.
    #
    def lsplug( plugins )
        print_line
        print_line
        print_info 'Available plugins:'
        print_line

        plugins.each do |info|
            print_status "#{info[:plug_name]}:"
            print_line '--------------------'

            print_line "Name:\t\t#{info[:name]}"
            print_line "Description:\t#{info[:description]}"

            if info[:options] && !info[:options].empty?
                print_line "Options:\t"

                info[:options].each do |option|
                    option = option.is_a?( Hash ) ? option : option.to_h

                    print_info "\t#{option['name']} - #{option['desc']}"
                    print_info "\tType:        #{option['type']}"
                    print_info "\tDefault:     #{option['default']}"
                    print_info "\tRequired?:   #{option['required?']}"

                    print_line
                end
            end

            print_line "Author:\t\t#{info[:author].join( ', ' )}"
            print_line "Version:\t#{info[:version]}"
            print_line "Path:\t#{info[:path]}"

            print_line
        end
    end

    #
    # Loads an Arachni Framework Profile file and merges it with the
    # user supplied options.
    #
    # @param    [Array<String>]    profiles    the files to load
    #
    def load_profile( profiles )
        exception_jail{
            @opts.load_profile = nil
            profiles.each { |filename| @opts.merge!( @opts.load( filename ) ) }
        }
    end

    #
    # Saves options to an Arachni Framework Profile file.
    #
    # @param    [String]    filename
    #
    def save_profile( filename )
        if filename = @opts.save( filename )
            print_status "Saved profile in '#{filename}'."
            print_line
        else
            banner
            print_error 'Could not save profile.'
            exit 0
        end
    end

    def print_profile
        print_info 'Running profile:'
        print_info @opts.to_args
    end

    #
    # Outputs Arachni banner.
    # Displays version number, revision number, author details etc.
    #
    # @see VERSION
    # @see REVISION
    #
    # @return [void]
    #
    def print_banner
        print_line BANNER
        print_line
        print_line
    end

    #
    # Outputs help/usage information.
    # Displays supported options and parameters.
    #
    # @return [void]
    #
    def usage( extra_usage = '' )
        extra_usage += ' '

        print_line <<USAGE
  Usage:  #{File.basename( $0 )} #{extra_usage}\[options\] url

  Supported options:


    General ----------------------

    -h
    --help                      Output this.

    --version                   Show version information and exit.

    -v                          Be verbose.

    --debug                     Show what is happening internally.
                                  (You should give it a shot sometime ;) )

    --only-positives            Echo positive results *only*.

    --http-req-limit=<integer>  Concurrent HTTP requests limit.
                                  (Default: #{@opts.http_req_limit})
                                  (Be careful not to kill your server.)
                                  (*NOTE*: If your scan seems unresponsive try lowering the limit.)

    --http-timeout=<integer>    HTTP request timeout in milliseconds.

    --cookie-jar=<filepath>     Netscape HTTP cookie file, use curl to create it.

    --cookie-string='<name>=<value>; <name2>=<value2>'

                                Cookies, as a string, to be sent to the web application.

    --user-agent=<string>       Specify user agent.

    --custom-header='<name>=<value>'

                                Specify custom headers to be included in the HTTP requests.
                                (Can be used multiple times.)

    --authed-by=<string>        Who authorized the scan, include name and e-mail address.
                                  (It'll make it easier on the sys-admins during log reviews.)
                                  (Will be appended to the user-agent string.)

    --login-check-url=<url>     A URL used to verify that the scanner is still logged in to the web application.
                                  (Requires 'login-check-pattern'.)

    --login-check-pattern=<regexp>

                                A pattern used against the body of the 'login-check-url' to verify that the scanner is still logged in to the web application.
                                  (Requires 'login-check-url'.)

    Profiles -----------------------

    --save-profile=<filepath>   Save the current run profile/options to <filepath>.

    --load-profile=<filepath>   Load a run profile from <filepath>.
                                  (Can be used multiple times.)
                                  (You can complement it with more options, except for:
                                      * --modules
                                      * --redundant)

    --show-profile              Will output the running profile as CLI arguments.


    Crawler -----------------------

    -e <regexp>
    --exclude=<regexp>          Exclude urls matching <regexp>.
                                  (Can be used multiple times.)

    --exclude-page=<regexp>     Exclude pages whose content matches <regexp>.
                                  (Can be used multiple times.)

    -i <regexp>
    --include=<regexp>          Include *only* urls matching <regex>.
                                  (Can be used multiple times.)

    --redundant=<regexp>:<limit>

                                Limit crawl on redundant pages like galleries or catalogs.
                                  (URLs matching <regexp> will be crawled <limit> amount of times.)
                                  (Can be used multiple times.)

    --auto-redundant=<limit>    Only follow <limit> amount of URLs with identical query parameter names.
                                  (Default: inf)
                                  (Will default to 10 if no value has been specified.)

    -f
    --follow-subdomains         Follow links to subdomains.
                                  (Default: off)

    --depth=<integer>           Directory depth limit.
                                  (Default: inf)
                                  (How deep Arachni should go into the site structure.)

    --link-count=<integer>      How many links to follow.
                                  (Default: inf)

    --redirect-limit=<integer>  How many redirects to follow.
                                  (Default: #{@opts.redirect_limit})

    --extend-paths=<filepath>   Add the paths in <file> to the ones discovered by the crawler.
                                  (Can be used multiple times.)

    --interceptor.callict-paths=<filepath> Use the paths in <file> instead of crawling.
                                  (Can be used multiple times.)

    --https-only                Forces the system to only follow HTTPS URLs.


    Auditor ------------------------

    -g
    --audit-links               Audit links.

    -p
    --audit-forms               Audit forms.

    -c
    --audit-cookies             Audit cookies.

    --exclude-cookie=<name>     Cookie to exclude from the audit by name.
                                  (Can be used multiple times.)

    --exclude-vector=<name>     Input vector (parameter) not to audit by name.
                                  (Can be used multiple times.)

    --audit-headers             Audit HTTP headers.
                                  (*NOTE*: Header audits use brute force.
                                   Almost all valid HTTP request headers will be audited
                                   even if there's no indication that the web app uses them.)
                                  (*WARNING*: Enabling this option will result in increased requests,
                                   maybe by an order of magnitude.)

    Coverage -----------------------

    --audit-cookies-extensively Submit all links and forms of the page along with the cookie permutations.
                                  (*WARNING*: This will severely increase the scan-time.)

    --fuzz-methods              Audit links, forms and cookies using both GET and POST requests.
                                  (*WARNING*: This will severely increase the scan-time.)

    --exclude-binaries          Exclude non text-based pages from the audit.
                                  (Binary content can confuse recon modules that perform pattern matching.)

    Modules ------------------------

    --lsmod=<regexp>            List available modules based on the provided regular expression.
                                  (If no regexp is provided all modules will be listed.)
                                  (Can be used multiple times.)


    -m <modname,modname,...>
    --modules=<modname,modname,...>

                                Comma separated list of modules to load.
                                  (Modules are referenced by their filename without the '.rb' extension, use '--lsmod' to list all.
                                   Use '*' as a module name to deploy all modules or as a wildcard, like so:
                                      xss*   to load all xss modules
                                      sqli*  to load all sql injection modules
                                      etc.

                                   You can exclude modules by prefixing their name with a minus sign:
                                      --modules=*,-backup_files,-xss
                                   The above will load all modules except for the 'backup_files' and 'xss' modules.

                                   Or mix and match:
                                      -xss*   to unload all xss modules.)


    Reports ------------------------

    --lsrep=<regexp>            List available reports based on the provided regular expression.
                                  (If no regexp is provided all reports will be listed.)
                                  (Can be used multiple times.)

    --repload=<filepath>        Load audit results from an '.afr' report file.
                                    (Allows you to create new reports from finished scans.)

    --report='<report>:<optname>=<val>,<optname2>=<val2>,...'

                                <report>: the name of the report as displayed by '--lsrep'
                                  (Reports are referenced by their filename without the '.rb' extension, use '--lsrep' to list all.)
                                  (Default: stdout)
                                  (Can be used multiple times.)


    Plugins ------------------------

    --lsplug=<regexp>           List available plugins based on the provided regular expression.
                                  (If no regexp is provided all plugins will be listed.)
                                  (Can be used multiple times.)

    --plugin='<plugin>:<optname>=<val>,<optname2>=<val2>,...'

                                <plugin>: the name of the plugin as displayed by '--lsplug'
                                  (Plugins are referenced by their filename without the '.rb' extension, use '--lsplug' to list all.)
                                  (Can be used multiple times.)

    Platforms ----------------------

    --lsplat                    List available platforms.

    --no-fingerprinting         Disable platform fingerprinting.
                                  (By default, the system will try to identify the deployed server-side platforms automatically
                                   in order to avoid sending irrelevant payloads.)

    --platforms=<platform,platform,...>

                                Comma separated list of platforms (by shortname) to audit.
                                  (The given platforms will be used *in addition* to fingerprinting. In order to restrict the audit to
                                   these platforms enable the '--no-fingerprinting' option.)

    Proxy --------------------------

    --proxy=<server:port>       Proxy address to use.

    --proxy-auth=<user:passwd>  Proxy authentication credentials.

    --proxy-type=<type>         Proxy type; can be http, http_1_0, socks4, socks5, socks4a
                                  (Default: http)


USAGE
    end

end

end
end
end
