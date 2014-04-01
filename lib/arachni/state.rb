=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

# Stores and provides access to the state of the system.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class State

    # {State} error namespace.
    #
    # All {State} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < Arachni::Error
    end

    require_relative 'state/options'
    require_relative 'state/audit'
    require_relative 'state/element_filter'
    require_relative 'state/framework'
    require_relative 'state/http'

class <<self

    # @return     [Options]
    attr_accessor :options

    # @return     [HTTP]
    attr_accessor :http

    # @return     [Audit]
    attr_accessor :audit

    # @return     [ElementFilter]
    attr_accessor :element_filter

    # @return     [Framework]
    attr_accessor :framework

    def reset
        @http           = HTTP.new
        @options        = Options.new
        @audit          = Audit.new
        @element_filter = ElementFilter.new
        @framework      = Framework.new
    end

    # @param    [String]    directory
    #   Location of the dump directory.
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
    # @return   [State]     `self`
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
        end.compact
    end

end

reset
end
end
