=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'json'

module Arachni

module Reports

class HTML
module PluginFormatters

    #
    # HTML formatter for the results of the Profiler plugin
    #
    # @author: Tasos "Zapotek" Laskos
    #                                      <tasos.laskos@gmail.com>
    #                                      <zapotek@segfault.gr>
    # @version: 0.1
    #
    class Profiler < Arachni::Plugin::Formatter

        def run

            @results['times'].each_with_index {
                |itm, i|
                @results['times'][i] = escape_hash( itm )
            }

            times      = @results['times'].map{ |item| item['time'] }
            total_time = 0
            times.each {
                |time|
                total_time += time
            }

            avg_time = total_time / times.size
            times.reject!{ |time| time < avg_time }

            return ERB.new( IO.read( File.dirname( __FILE__ ) + '/profiler/template.erb' ) ).result( binding )
        end

        def escape_hash( hash )
            hash.each_pair {
                |k, v|
                hash[k] = CGI.escape( v ) if v.is_a?( String )
                hash[k] = escape_hash( v ) if v.is_a? Hash
            }

            return hash
        end

    end

end
end

end
end
