=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni
class State

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Options

    def statistics
        {
            url:     Arachni::Options.url,
            checks:  Arachni::Options.checks,
            plugins: Arachni::Options.plugins.keys
        }
    end

    def dump( directory )
        FileUtils.mkdir_p( directory )
        Arachni::Options.save( "#{directory}/options" )
    end

    def self.load( directory )
        Arachni::Options.load( "#{directory}/options" )
        new
    end

    def clear
    end

end

end
end
