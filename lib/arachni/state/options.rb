=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni
class State

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
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
