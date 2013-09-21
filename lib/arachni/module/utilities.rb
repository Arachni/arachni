=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'addressable/uri'
require 'digest/sha1'
require 'cgi'

module Arachni
module Module

#
# Includes some useful methods for the system, the modules etc...
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
module Utilities
    include Arachni::Utilities

    #
    # Gets module data files from 'modules/[modtype]/[modname]/[filename]'
    #
    # @param    [String]    filename  filename, without the path
    # @param    [Block]     block     the block to be passed each line as it's read
    #
    def read_file( filename, &block )
        mod_path = block_given? ? block.source_location.first : caller.first.split(':').first

        # the name of the module that called us
        mod_name = File.basename( mod_path, ".rb" )

        # the path to the module's data file directory
        path  = File.expand_path( File.dirname( mod_path ) ) + '/' + mod_name + '/'

        file = File.open( path + '/' + filename )
        if block_given?
            # I really hope that ruby frees each line as soon as possible
            # otherwise this provides no advantage
            file.each { |line| yield line.strip }
        else
            file.read.lines.map { |l| l.strip }
        end
    ensure
        file.close
    end

    extend self

end

end
end
