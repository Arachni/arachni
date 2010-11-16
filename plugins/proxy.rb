=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# Passive proxy.
#
# Will gather data based on user actions and exhanged HTTP traffic and push that
# data to the {Framework#page_queue} to be audited.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Proxy < Arachni::Plugin::Base

    #
    # @param    [Arachni::Framework]    framework
    # @param    [Hash]        options    options passed to the plugin
    #
    def initialize( framework, options )
        @framework = framework
        @options   = options

        # don't let the framework run just yet
        @framework.pause!
    end

    def prepare
        require @framework.opts.dir['plugins'] + '/proxy/trainer_proxy.rb'
    end

    def run( )

        # start the proxy trainer
        ps = TrainerProxy.new( @framework, @options )
        ps.start

    end

    def clean_up
        # start the audit
        @framework.resume!
    end

    def self.info
        {
            :name           => 'Proxy',
            :description    => %q{.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptPort.new( 'port', [ false, 'Port to bind to.', 8282 ] ),
                Arachni::OptString.new( 'bind_address', [ false, 'IP address to bind to.', '0.0.0.0' ] )
            ]
        }
    end

end

end
end
