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
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Manager < Arachni::ComponentManager

    include Arachni::Module::Utilities

    DEFAULT = [
        'defaults/*'
    ]

    @@results ||= {}
    @@results_mutex ||= Mutex.new


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
    def run!

        ordered = []
        unordered = []
        loaded.each {
            |name|
            ph = { name => self[name] }
            if order = self[name].info[:order]
                ordered[order] ||= []
                ordered[order] << ph
            else
                unordered << ph
            end
        }
        ordered << unordered
        ordered.flatten!

        ordered.each {
            |ph|
            name = ph.keys.first
            plugin = ph.values.first

            if( ret = sane_env?( plugin ) ) != true
                if !ret[:gem_errors].empty?
                    print_bad( "[#{name}] The following plug-in dependencies aren't satisfied:" )
                    ret[:gem_errors].each {
                       |gem|
                        print_bad( "\t* #{gem}" )
                    }

                    deps = ret[:gem_errors].join( ' ' )
                    print_bad( "Try installing them by running:" )
                    print_bad( "\tgem install #{deps}" )
                end

                raise "Plug-in dependencies not met: #{name} -- #{deps}"
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
        }

        if @jobs.size > 0
            print_status( 'Waiting for plugins to settle...' )
            ::IO::select( nil, nil, nil, 1 )
        end
    end
    alias :run :run!

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
        return true if job && job.kill
        return false
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

    #
    # Registers plugin results
    #
    # @param    [Object]
    #
    def register_results( plugin, results )
        @@results_mutex.synchronize {

            name = nil
            self.each {
                |k, v|

                if plugin.class.name == v.name
                    name = k
                    break
                end
            }

            return if !name
            @@results[name] = { :results => results }.merge( plugin.class.info )
        }
    end

    def self.results() @@results end
    def results() self.class.results end

end
end
end
