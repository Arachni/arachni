=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end
require 'getoptlong'

# Construct getops struct
opts = GetoptLong.new(
    [ '--help',              '-h', GetoptLong::NO_ARGUMENT ],
    [ '--resume',            '-r', GetoptLong::NO_ARGUMENT ],
    [ '--verbosity',         '-v', GetoptLong::NO_ARGUMENT ],
    [ '--only-positives',    '-k', GetoptLong::NO_ARGUMENT ],
    [ '--lsmod',             '-l', GetoptLong::NO_ARGUMENT ],
    [ '--audit-links',       '-g', GetoptLong::NO_ARGUMENT ],
    [ '--audit-forms',       '-p', GetoptLong::NO_ARGUMENT ],
    [ '--audit-cookies',     '-c', GetoptLong::NO_ARGUMENT ],
    [ '--obey-robots-txt',   '-o', GetoptLong::NO_ARGUMENT ],
    [ '--delay',                   GetoptLong::REQUIRED_ARGUMENT ],
    [ '--depth',             '-d', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--redirect-limit',    '-q', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--threads',           '-t', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--link-count',        '-u', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--mods',              '-m', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--proxy',             '-z', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--proxy-auth',        '-x', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--proxy-type',        '-y', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--cookie-jar',        '-j', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--user-agent',        '-b', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--exclude',           '-e', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--include',           '-i', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--follow-subdomains', '-f', GetoptLong::NO_ARGUMENT ],
    [ '--mods-run-last',     '-s', GetoptLong::NO_ARGUMENT ],
    [ '--debug',             '-w', GetoptLong::NO_ARGUMENT ]
)

# TODO: remove global vars
$runtime_args = {};
$runtime_args['dir']         = Hash.new
    
$runtime_args['dir']['pwd']  =
    File.dirname( File.expand_path(__FILE__) ) + '/'
        
$runtime_args['dir']['modules'] = $runtime_args['dir']['pwd'] + 'modules/'
$runtime_args['dir']['lib']  = $runtime_args['dir']['pwd'] + 'lib/'

$runtime_args[:exclude] = []
    
opts.each do |opt, arg|

    case opt

        when '--help'
            $runtime_args[:help] = true

        when '--only-positives'
            $runtime_args[:only_positives] = true
                
        when '--resume'
            $runtime_args[:resume] = true

        when '--verbosity'
            $runtime_args[:arachni_verbose] = true

        when '--debug'
            $runtime_args[:debug] = true

        when '--obey_robots_txt'
            $runtime_args[:obey_robots_txt] = true

        when '--depth'
            $runtime_args[:depth_limit] = arg.to_i

        when '--link-count'
            $runtime_args[:link_count_limit] = arg.to_i

        when '--redirect-limit'
            $runtime_args[:redirect_limit] = arg.to_i

        when '--lsmod'
            $runtime_args[:lsmod] = true

        when '--threads'
            $runtime_args[:threads] = arg.to_i

        when '--audit-links'
            $runtime_args[:audit_links] = true

        when '--audit-forms'
            $runtime_args[:audit_forms] = true

        when '--audit-cookies'
            $runtime_args[:audit_cookies] = true

        when '--mods'
            $runtime_args[:mods] = arg.to_s.split( /,/ )

        when '--proxy'
            $runtime_args[:proxy_addr], $runtime_args[:proxy_port] =
                arg.to_s.split( /:/ )

        when '--proxy-auth'
            $runtime_args[:proxy_user], $runtime_args[:proxy_pass] =
                arg.to_s.split( /:/ )

        when '--proxy-type'
            $runtime_args[:proxy_type] = arg.to_s

        when '--cookie-jar'
            $runtime_args[:cookie_jar] = arg.to_s

        when '--user-agent'
            $runtime_args[:user_agent] = arg.to_s

        when '--exclude'
            $runtime_args[:exclude] << Regexp.new( arg )

        when '--include'
            $runtime_args[:include] = Regexp.new( arg )

        when '--follow-subdomains'
            $runtime_args[:follow_subdomains] = true

        when '--mods-run-last'
            $runtime_args[:mods_run_last] = true

    end
end

$runtime_args[:url] = ARGV.shift

#
# If proxy type is socks include socksify
# and let it proxy all tcp connections for us.
#
# Then nil out the proxy opts or else they're going to be
# passed as an http proxy to Anemone::HTTP.refresh_connection()
#
if $runtime_args[:proxy_type] == 'socks'
    require 'socksify'

    TCPSocket.socks_server = $runtime_args[:proxy_addr]
    TCPSocket.socks_port = $runtime_args[:proxy_port]

    $runtime_args[:proxy_addr] = nil
    $runtime_args[:proxy_port] = nil
end
