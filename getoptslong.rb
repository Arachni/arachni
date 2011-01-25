=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'getoptlong'

# Construct getops struct
opts = GetoptLong.new(
    [ '--help',              '-h', GetoptLong::NO_ARGUMENT ],
    [ '--verbosity',         '-v', GetoptLong::NO_ARGUMENT ],
    [ '--only-positives',    '-k', GetoptLong::NO_ARGUMENT ],
    [ '--lsmod',                   GetoptLong::OPTIONAL_ARGUMENT ],
    [ '--lsrep',                   GetoptLong::OPTIONAL_ARGUMENT ],
    [ '--audit-links',       '-g', GetoptLong::NO_ARGUMENT ],
    [ '--audit-forms',       '-p', GetoptLong::NO_ARGUMENT ],
    [ '--audit-cookies',     '-c', GetoptLong::NO_ARGUMENT ],
    [ '--audit-cookie-jar',        GetoptLong::NO_ARGUMENT ],
    [ '--audit-headers',           GetoptLong::NO_ARGUMENT ],
    [ '--spider-first',            GetoptLong::NO_ARGUMENT ],
    [ '--obey-robots-txt',   '-o', GetoptLong::NO_ARGUMENT ],
    [ '--redundant',               GetoptLong::REQUIRED_ARGUMENT ],
    [ '--depth',             '-d', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--redirect-limit',    '-q', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--link-count',        '-u', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--mods',              '-m', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--report',                  GetoptLong::REQUIRED_ARGUMENT ],
    [ '--repload',                 GetoptLong::REQUIRED_ARGUMENT ],
    [ '--authed-by',               GetoptLong::REQUIRED_ARGUMENT ],
    [ '--load-profile',            GetoptLong::REQUIRED_ARGUMENT ],
    [ '--save-profile',            GetoptLong::REQUIRED_ARGUMENT ],
    [ '--show-profile',            GetoptLong::NO_ARGUMENT ],
    [ '--proxy',             '-z', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--proxy-auth',        '-x', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--proxy-type',        '-y', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--cookie-jar',        '-j', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--user-agent',        '-b', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--exclude',           '-e', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--include',           '-i', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--exclude-cookie',          GetoptLong::REQUIRED_ARGUMENT ],
    [ '--http-req-limit',          GetoptLong::REQUIRED_ARGUMENT ],
    [ '--follow-subdomains', '-f', GetoptLong::NO_ARGUMENT ],
    [ '--http-harvest-last',  '-s', GetoptLong::NO_ARGUMENT ],
    [ '--debug',             '-w', GetoptLong::NO_ARGUMENT ],
    [ '--ssl',                     GetoptLong::NO_ARGUMENT ],
    [ '--server',                  GetoptLong::REQUIRED_ARGUMENT ],
    [ '--plugin',                  GetoptLong::OPTIONAL_ARGUMENT ],
    [ '--lsplug',                  GetoptLong::OPTIONAL_ARGUMENT ],
)

$:.unshift( File.expand_path( File.dirname( __FILE__ ) ) )

require 'lib/options'
options = Arachni::Options.instance

options.dir            = Hash.new
options.dir['root']    = File.dirname( File.expand_path(__FILE__) ) + '/'
options.dir['modules'] = options.dir['root'] + 'modules/'
options.dir['reports'] = options.dir['root'] + 'reports/'
options.dir['plugins'] = options.dir['root'] + 'plugins/'
options.dir['lib']     = options.dir['root'] + 'lib/'

opts.quiet = true

begin
    opts.each {
        |opt, arg|

        case opt

            when '--help'
                options.help = true

            when '--only-positives'
                options.only_positives = true

            when '--verbosity'
                options.arachni_verbose = true

            when '--debug'
                options.debug = true

            when '--spider-first'
                options.spider_first = true

            when '--plugin'
                plugin, opt_str = arg.split( ':', 2 )

                opts = {}
                if( opt_str )
                    opt_arr = opt_str.split( ',' )
                    opt_arr.each {
                        |opt|
                        name, val = opt.split( '=', 2 )
                        opts[name] = val
                    }
                end

                options.plugins[plugin] = opts

            when '--redundant'
                options.redundant << {
                    'regexp'  => Regexp.new( arg.to_s.split( /:/ )[0] ),
                    'count'   => Integer( arg.to_s.split( /:/ )[1] ),
                }

            when '--obey_robots_txt'
                options.obey_robots_txt = true

            when '--depth'
                options.depth_limit = arg.to_i

            when '--link-count'
                options.link_count_limit = arg.to_i

            when '--redirect-limit'
                options.redirect_limit = arg.to_i

            when '--lsmod'
                options.lsmod << Regexp.new( arg.to_s )

            when '--lsplug'
                options.lsplug << Regexp.new( arg.to_s )

            when '--lsrep'
                options.lsrep << Regexp.new( arg.to_s )

            when '--http-req-limit'
              options.http_req_limit = arg.to_i

            when '--audit-links'
                options.audit_links = true

            when '--audit-forms'
                options.audit_forms = true

            when '--audit-cookies'
                options.audit_cookies = true

            when '--audit-cookie-jar'
                options.audit_cookie_jar = true

            when '--audit-headers'
                options.audit_headers = true

            when '--mods'
                options.mods = arg.to_s.split( /,/ )

            when '--report'
                report, opt_str = arg.split( ':' )

                opts = {}
                if( opt_str )
                    opt_arr = opt_str.split( ',' )
                    opt_arr.each {
                        |opt|
                        name, val = opt.split( '=' )
                        opts[name] = val
                    }
                end

                options.reports[report] = opts

            when '--repload'
                options.repload = arg

            when '--save-profile'
                options.save_profile = arg

            when '--load-profile'
                options.load_profile << arg

            when '--show-profile'
                options.show_profile = true

            when '--authed-by'
                options.authed_by = arg

            when '--proxy'
                options.proxy_addr, options.proxy_port =
                    arg.to_s.split( /:/ )

            when '--proxy-auth'
                options.proxy_user, options.proxy_pass =
                    arg.to_s.split( /:/ )

            when '--proxy-type'
                options.proxy_type = arg.to_s

            when '--cookie-jar'
                options.cookie_jar = arg.to_s

            when '--user-agent'
                options.user_agent = arg.to_s

            when '--exclude'
                options.exclude << Regexp.new( arg )

            when '--include'
                options.include << Regexp.new( arg )

            when '--exclude-cookie'
                options.exclude_cookies << arg

            when '--follow-subdomains'
                options.follow_subdomains = true

            when '--http-harvest-last'
                options.http_harvest_last = true

            when '--ssl'
                options.ssl = true

            when '--server'
                options.server = arg.to_s

        end
    }
rescue Exception => e
    puts e.inspect
    exit
end

options.url = ARGV.shift
