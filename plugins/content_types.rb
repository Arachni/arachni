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
# Logs content-types of all server responses.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class ContentTypes < Arachni::Plugin::Base

    #
    # @param    [Arachni::Framework]    framework
    # @param    [Hash]        options    options passed to the plugin
    #
    def initialize( framework, options )
        @framework = framework
        @options   = options
    end

    def prepare
        @results = {}
        @exclude = Regexp.new( @options['exclude'] )

        @logged = Set.new
    end

    def run( )
        @framework.http.on_complete {
            |res|

            next if @logged.include?( res.request.method.to_s.upcase + res.effective_url )
            next if !(type = res.headers_hash['Content-type'] ) || type.empty?

            if( !@options['exclude'].empty? && !type.match( @exclude ) ) ||
                @options['exclude'].empty?
                @results[type] ||= []
                @results[type] << {
                    :url    => res.effective_url,
                    :method => res.request.method.to_s.upcase,
                    :params => res.request.params
                }

                @logged << res.request.method.to_s.upcase + res.effective_url
            end
        }
    end

    def clean_up
        # we need to wait until the framework has finished running
        # before logging the results
        while( @framework.running? )
            ::IO.select( nil, nil, nil, 1 )
        end

        register_results( @results )
    end

    def self.info
        {
            :name           => 'Content-types',
            :description    => %q{Logs content-types of server responses.
                It can help you categorize and identify publicly available file-types
                which in turn can help you identify accidentally leaked files.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptString.new( 'exclude', [ false,
                    'Exclude content-types that match this regular expression.', 'text' ]
                )
            ]
        }
    end

end

end
end
