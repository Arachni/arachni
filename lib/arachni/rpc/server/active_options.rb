=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
module RPC
class Server

# It, for the most part, forwards calls to {Arachni::Options} and intercepts
# a few that need to be updated at other places throughout the framework.
#
# @private
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class ActiveOptions

    def initialize( framework )
        @framework = framework
        @options   = framework.options

        (@options.public_methods( false ) - public_methods( false ) ).each do |m|
            self.class.class_eval do
                define_method m do |*args|
                    @options.send( m, *args )
                end
            end
        end
    end

    # @see Arachni::Options#set
    def set( options )
        @options.set( options )

        if @framework.running?

            HTTP::Client.reset_options

            # Scope may have been updated.
            @framework.sitemap.reject! { |k, v| Utilities.skip_path? k }

            @options.scope.extend_paths.each do |url|
                @framework.push_to_url_queue( url )
            end

        # Only mess with HTTP state if this is the pre-run config.
        else
            HTTP::Client.reset false
        end

        true
    end

    def to_h
        @options.to_rpc_data
    end

end

end
end
end
