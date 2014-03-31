=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

# Stores and provides access to the data of the system.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Data

    # {Data} error namespace.
    #
    # All {Data} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Arachni::Error
    end

    require_relative 'data/framework'
    require_relative 'data/issues'
    require_relative 'data/plugins'

class <<self

    # @return     [Framework]
    attr_accessor :framework

    # @return     [Issues]
    attr_accessor :issues

    # @return     [Plugins]
    attr_accessor :plugins

    def reset
        @framework = Framework.new
        @issues    = Issues.new
        @plugins   = Plugins.new
    end

    # @param    [String]    directory
    #   Location of the dump directory.
    # @return   [String]
    #   Location of the dump directory.
    def dump( directory )
        FileUtils.mkdir_p( directory )

        each do |name, state|
            state.dump( "#{directory}/#{name}/" )
        end

        directory
    end

    # @param    [String]    directory
    #   Location of the dump directory.
    # @return   [Data]     `self`
    def load( directory )
        each do |name, state|
            send( "#{name}=", state.class.load( "#{directory}/#{name}/" ) )
        end

        self
    end

    # Clears all data.
    def clear
        each { |_, state| state.clear }
        self
    end

    private

    def each( &block )
        [:framework, :issues, :plugins].each do |attr|
            block.call attr, send( attr )
        end
    end

end

reset
end
end
