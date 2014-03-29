=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'fileutils'
require_relative 'state/issues'
require_relative 'state/plugins'
require_relative 'state/audit'
require_relative 'state/element_filter'
require_relative 'state/framework'

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

class <<self

    # @return     [Issues]
    attr_accessor :issues

    # @return     [Plugins]
    attr_accessor :plugins

    # @return     [Audit]
    attr_accessor :audit

    # @return     [ElementFilter]
    attr_accessor :element_filter

    # @return     [Framework]
    attr_accessor :framework

    def reset
        @issues         = Issues.new
        @plugins        = Plugins.new
        @audit          = Audit.new
        @element_filter = ElementFilter.new
        @framework      = Framework.new
    end

    def dump( directory )
        FileUtils.rm_rf( directory )
        FileUtils.mkdir_p( directory )

        each do |name, state|
            state.dump( "#{directory}/#{name}/" )
        end
    end

    def load( directory )
        each do |name, state|
            klass.send( "#{name}=", state.class.load( "#{directory}/#{name}/" ) )
        end
    end

    def compress( directory )
    end

    def clear
        each do |_, state|
            state.clear
        end
    end

    private

    def each( &block )
        [:issues, :plugins, :audit, :element_filter, :framework].each do |attr|
            block.call attr, send( attr )
        end
    end


end
reset
end
end
