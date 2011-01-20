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
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class CookieCollector < Arachni::Plugin::Base

    #
    # @param    [Arachni::Framework]    framework
    # @param    [Hash]        options    options passed to the plugin
    #
    def initialize( framework, options )
        super( framework, options )
    end

    def prepare
        @cookies = []
    end

    def run( )
        @framework.http.on_complete {
            |res|
            update( extract_cookies( res ), res )
        }
    end

    def update( cookies, res )
        return if cookies.empty? || !update?( cookies )

        @cookies << {
            :time       => Time.now,
            :res        => res.to_hash,
            :cookies    => cookies
        }
    end

    def update?( cookies )
        return true if @cookies.empty?

        cookies.each_pair {
            |k, v|
            return true if @cookies.last[:cookies][k] != v
        }

        return false
    end

    def extract_cookies( res )
        cookies = {}
        parser = Arachni::Parser.new( @framework.opts, res )
        parser.cookies.each {
            |cookie|
            cookies.merge!( cookie.simple )
        }

        return cookies
    end

    def clean_up
        while( @framework.running? )
            ::IO.select( nil, nil, nil, 1 )
        end

        register_results( @cookies )
    end


    def self.info
        {
            :name           => 'Cookie collector',
            :description    => %q{Monitors and collects cookies while establishing
                a timeline of changes.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
        }
    end

end

end
end
