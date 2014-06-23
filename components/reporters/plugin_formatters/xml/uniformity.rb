=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

class Arachni::Reporters::XML

# XML formatter for the results of the Uniformity plugin.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class PluginFormatters::Uniformity < Arachni::Plugin::Formatter

    def run
        uniformals = results['uniformals']

        uniformals.each do |id, uniformal|
            start_uniformals id

            uniformal['hashes'].each_with_index do |hash, i|
                add_uniformal( i, uniformal )
            end

            end_tag 'uniformals'
        end

        buffer
    end

    def add_uniformal( idx, uniformal )
        append "<issue index=\"#{uniformal['indices'][idx]}\"" +
            " hash=\"#{uniformal['hashes'][idx]}\" />"
    end

    def start_uniformals( id )
        append "<uniformals id=\"#{id}\">"
    end


end
end
