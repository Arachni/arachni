=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

#
# The namespace under which all plugins exist
#
module Plugins

    #
    # Resets the namespace unloading all module classes
    #
    def self.reset
        constants.each {
            |const|
            remove_const( const )
        }
    end
end

module Plugin

#
# Holds and manages the plugins.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Manager < Arachni::ComponentManager

    include Arachni::UI::Output

    #
    # @param    [Arachni::Options]    opts
    #
    def initialize( framework )
        super( framework.opts.dir['plugins'], Arachni::Plugins )
        @framework = framework

        @jobs = []
    end

    def run
        each {
            |name, plugin|

            opts = @framework.opts.plugins[name]

            @jobs << Thread.new {

                Thread.current[:name] = name

                plugin_new = plugin.new( @framework, prep_opts( name, plugin, opts ) )
                plugin_new.prepare
                plugin_new.run
                plugin_new.clean_up
            }
        }
    end

    def block!
        while( !@jobs.empty? )

            print_line
            print_info( "Waiting on the following (#{@jobs.size}) plugins to finish:" )
            print_info( job_names.join( ', ' ) )
            print_line

            @jobs.delete_if { |j| !j.alive? }
            ::IO::select( nil, nil, nil, 1 )
        end
    end

    def busy?
        !@jobs.reject{ |j| j.alive? }.empty?
    end

    def job_names
        @jobs.map{ |j| j[:name] }
    end

    def jobs
        @jobs
    end

    def kill( name )
        job = get( name )
        return job.kill if job
        return nil
    end

    def get( name )
        @jobs.each { |job| return job if job[:name] == name }
    end


end
end
end
