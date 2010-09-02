=begin
                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end
require 'getoptlong'

# Construct getops struct
opts = GetoptLong.new(
    [ '--help',              '-h', GetoptLong::NO_ARGUMENT ],
    [ '--resume',            '-r', GetoptLong::NO_ARGUMENT ],
    [ '--verbosity',         '-v', GetoptLong::NO_ARGUMENT ],
    [ '--only-positives',    '-k', GetoptLong::NO_ARGUMENT ],
    [ '--lsmod',                   GetoptLong::NO_ARGUMENT ],
    [ '--lsrep',                   GetoptLong::NO_ARGUMENT ],
    [ '--audit-links',       '-g', GetoptLong::NO_ARGUMENT ],
    [ '--audit-forms',       '-p', GetoptLong::NO_ARGUMENT ],
    [ '--audit-cookies',     '-c', GetoptLong::NO_ARGUMENT ],
    [ '--audit-cookie-jar',        GetoptLong::NO_ARGUMENT ],
    [ '--audit-headers',           GetoptLong::NO_ARGUMENT ],
    [ '--obey-robots-txt',   '-o', GetoptLong::NO_ARGUMENT ],
    [ '--delay',                   GetoptLong::REQUIRED_ARGUMENT ],
    [ '--redundant',               GetoptLong::REQUIRED_ARGUMENT ],
    [ '--depth',             '-d', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--redirect-limit',    '-q', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--threads',           '-t', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--link-count',        '-u', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--mods',              '-m', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--report',                  GetoptLong::REQUIRED_ARGUMENT ],
    [ '--repload',                 GetoptLong::REQUIRED_ARGUMENT ],
    [ '--repopts',                 GetoptLong::REQUIRED_ARGUMENT ],
    [ '--authed-by',               GetoptLong::REQUIRED_ARGUMENT ],
    [ '--repsave',                 GetoptLong::REQUIRED_ARGUMENT ],
    [ '--load-profile',            GetoptLong::REQUIRED_ARGUMENT ],
    [ '--save-profile',            GetoptLong::REQUIRED_ARGUMENT ],
    [ '--proxy',             '-z', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--proxy-auth',        '-x', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--proxy-type',        '-y', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--cookie-jar',        '-j', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--user-agent',        '-b', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--exclude',           '-e', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--include',           '-i', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--exclude-cookie',          GetoptLong::REQUIRED_ARGUMENT ],
    [ '--follow-subdomains', '-f', GetoptLong::NO_ARGUMENT ],
    [ '--mods-run-last',     '-s', GetoptLong::NO_ARGUMENT ],
    [ '--debug',             '-w', GetoptLong::NO_ARGUMENT ]
)

$:.unshift( File.expand_path( File.dirname( __FILE__ ) ) ) 

require 'lib/options'
options = Arachni::Options.instance

options.dir            = Hash.new
options.dir['pwd']     = File.dirname( File.expand_path(__FILE__) ) + '/'
options.dir['modules'] = options.dir['pwd'] + 'modules/'
options.dir['reports'] = options.dir['pwd'] + 'reports/'
options.dir['lib']     = options.dir['pwd'] + 'lib/'

opts.each {
    |opt, arg|

    case opt

        when '--help'
            options.help = true

        when '--only-positives'
            options.only_positives = true
                
        when '--resume'
            options.resume = true

        when '--verbosity'
            options.arachni_verbose = true

        when '--debug'
            options.debug = true
                        
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
            options.lsmod = true
    
        when '--lsrep'
            options.lsrep = true
                
        when '--threads'
            options.threads = arg.to_i

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
            options.reports << arg
        
        when '--repload'
            options.repload = arg
        
        when '--repsave'
            options.repsave = arg

        when '--repopts'
            arg.split( /,/ ).each {
                |opt|
                
                name, value = opt.split( /:/ )
                options.repopts[name] = value
            }
                
        when '--save-profile'
            options.save_profile = arg

        when '--load-profile'
            options.load_profile = arg
                        
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

        when '--mods-run-last'
            options.mods_run_last = true

    end
}

options.url = ARGV.shift

#
# If proxy type is socks include socksify
# and let it proxy all tcp connections for us.
#
# Then nil out the proxy opts or else they're going to be
# passed as an http proxy to Anemone::HTTP.refresh_connection()
#
if options.proxy_type == 'socks'
    require 'socksify'

    TCPSocket.socks_server = options.proxy_addr
    TCPSocket.socks_port = options.proxy_port

    options.proxy_addr = nil
    options.proxy_port = nil
end
