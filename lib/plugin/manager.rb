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
    include Arachni::Module::Utilities

    #
    # @param    [Arachni::Framework]    framework   framework instance
    #
    def initialize( framework )
        super( framework.opts.dir['plugins'], Arachni::Plugins )
        @framework = framework

        @jobs = []
    end

    #
    # Runs each plug-in in its own thread.
    #
    def run
        i = 0
        each {
            |name, plugin|

            @jobs << Thread.new {

                exception_jail {
                    Thread.current[:name] = name

                    plugin_new = create( name )
                    plugin_new.prepare
                    plugin_new.run
                    plugin_new.clean_up
                }

            }

            i += 1
        }

        if i > 0
            print_status( 'Waiting for plugins to settle...' )
            ::IO::select( nil, nil, nil, 1 )
        end
    end

    def create( name )
        opts = @framework.opts.plugins[name]
        self[name].new( @framework, prep_opts( name, self[name], opts ) )
    end

    #
    # Blocks until all plug-ins have finished executing.
    #
    def block!
        while( !@jobs.empty? )

            print_debug
            print_debug( "Waiting on the following (#{@jobs.size}) plugins to finish:" )
            print_debug( job_names.join( ', ' ) )
            print_debug

            @jobs.delete_if { |j| !j.alive? }
            ::IO::select( nil, nil, nil, 1 )
        end
    end

    #
    # Will return false if all plug-ins have finished executing.
    #
    # @return   [Bool]
    #
    def busy?
        !@jobs.reject{ |j| j.alive? }.empty?
    end

    #
    # Returns the names of the running plug-ins.
    #
    # @return   [Array]
    #
    def job_names
        @jobs.map{ |j| j[:name] }
    end

    #
    # Returns all the running threads.
    #
    # @return   [Array<Thread>]
    #
    def jobs
        @jobs
    end

    #
    # Kills a plug-in by name.
    #
    # @param    [String]    name
    #
    def kill( name )
        job = get( name )
        return job.kill if job
        return nil
    end

    #
    # Gets a running plug-in by name.
    #
    # @param    [String]    name
    #
    # @return   [Thread]
    #
    def get( name )
        @jobs.each { |job| return job if job[:name] == name }
    end


end
end
end
