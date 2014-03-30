=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'zip'
require 'fileutils'
require_relative 'state/options'
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

    # @return     [Options]
    attr_accessor :options

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
        @options        = Options.new
        @issues         = Issues.new
        @plugins        = Plugins.new
        @audit          = Audit.new
        @element_filter = ElementFilter.new
        @framework      = Framework.new
    end

    # @param    [String]    archive
    #   Location of the archive.
    # @return   [String]
    #   Location of the archive.
    def dump( archive )
        directory = get_temporary_directory

        FileUtils.rm_rf( directory )
        FileUtils.mkdir_p( directory )

        begin
            each do |name, state|
                state.dump( "#{directory}/#{name}/" )
            end

            compress directory, archive
        ensure
            FileUtils.rm_rf( directory )
        end
    end

    # @param    [String]    archive
    #   Location of the archive.
    # @return   [State]     `self`
    def load( archive )
        directory = get_temporary_directory

        begin
            decompress( archive, directory )

            each do |name, state|
                send( "#{name}=", state.class.load( "#{directory}/#{name}/" ) )
            end

            self
        ensure
            # FileUtils.rm_rf( directory )
        end
    end

    # Clears all states.
    def clear
        each { |_, state| state.clear }
        self
    end

    private

    def get_temporary_directory
        "#{Dir.tmpdir}/Arachni_State_#{Utilities.generate_token}/"
    end

    def each( &block )
        [:options, :issues, :plugins, :audit, :element_filter, :framework].each do |attr|
            block.call attr, send( attr )
        end
    end

    def decompress( archive, directory )
        Zip::File.open( archive ) do |zip_file|
            zip_file.each do |f|
                f_path = File.join( directory, f.name )
                FileUtils.mkdir_p( File.dirname( f_path ) )
                zip_file.extract( f, f_path ) unless File.exist?( f_path )
            end
        end

        directory
    end

    def compress( directory, archive )
        Zip::File.open( archive, Zip::File::CREATE ) do |zipfile|
            Dir[File.join(directory, '**', '**')].each do |file|
                zipfile.add( file.sub( directory, '' ), file )
            end
        end

        archive
    end

end
reset
end
end
