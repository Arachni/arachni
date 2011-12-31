=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Resolver < Arachni::Plugin::Base

    def prepare
        wait_while_framework_running
    end

    def run
        print_status 'Resolving hostnames...'

        host_to_ipaddress = {}
        @framework.audit_store.deep_clone.issues.each_with_index {
            |issue|
            exception_jail( false ) {
                host = URI( issue.url ).host
                host_to_ipaddress[host] ||= ::IPSocket.getaddress( host )
            }
        }
        print_status 'Done!'

        register_results( host_to_ipaddress )
    end

    def self.info
        {
            :name           => 'Resolver',
            :description    => %q{Resolves vulnerable hostnames to IP addresses.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :tags           => [ 'ip address', 'hostname' ],
            :version        => '0.1'
        }
    end

end

end
end
