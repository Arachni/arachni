=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

# Stores and provides access to the data of the system.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Data

    # {Data} error namespace.
    #
    # All {Data} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::Error
    end

    require_relative 'data/framework'
    require_relative 'data/session'
    require_relative 'data/issues'
    require_relative 'data/plugins'

class <<self

    # @return     [Framework]
    attr_accessor :framework

    # @return     [Session]
    attr_accessor :session

    # @return     [Issues]
    attr_accessor :issues

    # @return     [Plugins]
    attr_accessor :plugins

    def reset
        @framework = Framework.new
        @session   = Session.new
        @issues    = Issues.new
        @plugins   = Plugins.new
    end

    def statistics
        stats = {}
        each do |attribute|
            stats[attribute] = send(attribute).statistics
        end
        stats
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
        accessors.each do |attr|
            block.call attr, send( attr )
        end
    end

    def accessors
        instance_variables.map do |ivar|
            attribute = "#{ivar.to_s.gsub('@','')}"
            next if !methods.include?( :"#{attribute}=" )
            attribute.to_sym
        end.compact
    end

end

reset
end
end
