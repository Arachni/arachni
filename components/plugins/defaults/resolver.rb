=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# @author Tasos "Zapotek" Laskos<tasos.laskos@gmail.com>
# @version 0.1.2
class Arachni::Plugins::Resolver < Arachni::Plugin::Base

    def prepare
        wait_while_framework_running
    end

    def run
        print_status 'Resolving hostnames...'

        host_to_ipaddress = {}
        framework.auditstore.issues.each_with_index do |issue|
            uri = uri_parse( issue.vector.action )
            next if !uri

            host = uri.host

            begin
                host_to_ipaddress[host] ||= ::IPSocket.getaddress( host )
            rescue
                print_bad "Could not resolve #{host}."
                next
            end
        end

        print_status 'Done!'
        register_results( host_to_ipaddress )
    end

    def self.info
        {
            name:        'Resolver',
            description: %q{Resolves vulnerable hostnames to IP addresses.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            tags:        [ 'ip address', 'hostname' ],
            version:     '0.1.2'
        }
    end

end
