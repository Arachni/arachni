#!/usr/bin/env ruby
=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'getoptlong'
require 'pp'
require 'ap'

$:.unshift( File.expand_path( File.dirname( __FILE__ ) ) )

require 'lib/options'
options = Arachni::Options.instance

options.dir            = Hash.new
options.dir['pwd']     = File.dirname( File.expand_path(__FILE__) ) + '/'
options.dir['modules'] = options.dir['pwd'] + 'modules/'
options.dir['reports'] = options.dir['pwd'] + 'reports/'
options.dir['lib']     = options.dir['pwd'] + 'lib/'

# Construct getops struct
opts = GetoptLong.new(
    [ '--help',             '-h', GetoptLong::NO_ARGUMENT ],
    [ '--port',                   GetoptLong::OPTIONAL_ARGUMENT ],
    [ '--ssl',                    GetoptLong::NO_ARGUMENT ],
    [ '--ssl-pkey',               GetoptLong::REQUIRED_ARGUMENT ],
    [ '--ssl-cert',               GetoptLong::REQUIRED_ARGUMENT ],
    [ '--ssl-bundle',             GetoptLong::REQUIRED_ARGUMENT ],
)

begin
    opts.each {
        |opt, arg|

        case opt

            when '--help'
                options.help = true

            when '--port'
                options.rpc_port = arg.to_i

            when '--ssl'
                options.ssl = true

            when '--ssl-pkey'
                options.ssl_pkey = arg.to_s

            when '--ssl-cert'
                options.ssl_cert = arg.to_s

            when '--ssl-bundle'
                options.ssl_bundle = arg.to_s

        end
    }
end

require options.dir['lib'] + 'ui/xmlrpcd/xmlrpcd'

server = Arachni::UI::XMLRPCD.new( Arachni::Options.instance )
server.run
