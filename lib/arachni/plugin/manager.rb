=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni

#
# The namespace under which all plugins exist
#
module Plugins
end

module Plugin

#
# Holds and manages the plugins.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class Manager < Arachni::ComponentManager

    include Arachni::Module::Utilities

    DEFAULT = [
        'defaults/*'
    ]

    #
    # @param    [Arachni::Framework]    framework   framework instance
    #
    def initialize( framework )
        super( framework.opts.dir['plugins'], Arachni::Plugins )
        @framework = framework

        @jobs = []
    end

    def load_defaults!
        load( DEFAULT )
    end

    #
    # Runs each plug-in in its own thread.
    #
    def run
        i = 0
        each {
            |name, plugin|

            if( ret = sane_env?( plugin ) ) != true
                if !ret[:gem_errors].empty?
                    print_error( "[#{name}] The following plug-in dependencies aren't satisfied:" )
                    ret[:gem_errors].each {
                       |gem|
                        print_info( "\t* #{gem}" )
                    }

                    print_info( "Try installing them by running:" )
                    print_info( "\tgem install #{ret[:gem_errors].join( ' ' )}" )
                end

                raise
            end

            @jobs << Thread.new {

                exception_jail( false ) {
                    Thread.current[:name] = name

                    Thread.current[:instance] = plugin_new = create( name )
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

    def sane_env?( plugin )
        gem_errors = []

        plugin.gems.each {
            |gem|
            begin
                require gem
            rescue Exception => e
                gem_errors << gem
            end
        }

        return {
            :gem_errors => gem_errors
        } if !gem_errors.empty?

        return true
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
        return
    end


end
end
end
