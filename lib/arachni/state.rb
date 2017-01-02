=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

# Stores and provides access to the state of the system.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class State

    # {State} error namespace.
    #
    # All {State} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    class Error < Arachni::Error
    end

    require_relative 'state/options'
    require_relative 'state/plugins'
    require_relative 'state/audit'
    require_relative 'state/element_filter'
    require_relative 'state/framework'
    require_relative 'state/http'

class <<self

    # @return     [Options]
    attr_accessor :options

    # @return     [HTTP]
    attr_accessor :http

    # @return     [Plugins]
    attr_accessor :plugins

    # @return     [Audit]
    attr_accessor :audit

    # @return     [ElementFilter]
    attr_accessor :element_filter

    # @return     [Framework]
    attr_accessor :framework

    def reset
        @http           = HTTP.new
        @plugins        = Plugins.new
        @options        = Options.new
        @audit          = Audit.new
        @element_filter = ElementFilter.new
        @framework      = Framework.new
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
    #
    # @return   [String]
    #   Location of the directory.
    def dump( directory )
        FileUtils.mkdir_p( directory )

        each do |name, state|
            state.dump( "#{directory}/#{name}/" )
        end

        directory
    end

    # @param    [String]    directory
    #   Location of the dump directory.
    #
    # @return   [State]
    #   `self`
    def load( directory )
        each do |name, state|
            send( "#{name}=", state.class.load( "#{directory}/#{name}/" ) )
        end

        self
    end

    # Clears all states.
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
            attribute
        end.compact.map(&:to_sym)
    end

end

reset
end
end
