=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class State

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class HTTP

    # @return   [Hash]
    #   HTTP headers for the {Arachni::HTTP::Client#headers}.
    attr_reader :headers

    # @return   [CookieJar]
    #   Cookie-jar for {Arachni::HTTP::Client#cookie_jar}.
    attr_reader :cookie_jar

    def initialize
        @headers    = Arachni::HTTP::Headers.new
        @cookie_jar = Arachni::HTTP::CookieJar.new
    end

    def statistics
        {
            cookies: @cookie_jar.cookies.map(&:to_s).uniq
        }
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )

        %w(headers cookie_jar).each do |attribute|
            IO.binwrite( "#{directory}/#{attribute}", Marshal.dump( send(attribute) ) )
        end
    end

    def self.load( directory )
        http = new

        %w(headers cookie_jar).each do |attribute|
            http.send(attribute).merge! Marshal.load( IO.binread( "#{directory}/#{attribute}" ) )
        end

        http
    end

    def clear
        @cookie_jar.clear
        @headers.clear
    end

end
end
end

