=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Arachni

#
# The namespace under which all plugins exist.
#
module Plugins
end

module Plugin

class Error < Arachni::Error
    class UnsatisfiedDependency < Error
    end
end

#
# Holds and manages the plugins.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Manager < Arachni::Component::Manager
    # Namespace under which all plugins reside.
    NAMESPACE = Arachni::Plugins

    # Expressions matching default plugins.
    DEFAULT   = %w(defaults/*)

    # @param    [Arachni::Framework]    framework   Framework instance.
    def initialize( framework )
        super( framework.opts.paths.plugins, NAMESPACE )
        @framework = framework

        @jobs = []
    end

    # Loads the default plugins.
    #
    # @see DEFAULT
    def load_default
        load DEFAULT
    end
    alias :load_defaults :load_default

    # @return   [Array<String>] Components to load, by name.
    def default
        parse DEFAULT
    end
    alias :defaults :default

    # Runs each plug-in in its own thread.
    #
    # @raise [Error::UnsatisfiedDependency]
    #   If the environment is {#sane_env? not sane}.
    def run
        prepare.each do |name, options|
            @jobs << Thread.new do
                exception_jail( false ) do
                    Thread.current[:instance] = create( name, options )
                    Thread.current[:instance].prepare
                    Thread.current[:instance].run
                    Thread.current[:instance].clean_up
                end
            end
        end

        return if @jobs.empty?

        print_status 'Waiting for plugins to settle...'
        sleep 1
    end

    # @return   [Hash]
    #   Sorted plugins with their prepared options.
    #
    # @raise [Error::UnsatisfiedDependency]
    #   If the environment is not {#sane_env? sane}.
    def prepare
        ordered   = []
        unordered = []

        loaded.each do |name|
            ph = { name => self[name] }

            if (order = self[name].info[:priority])
                ordered[order] ||= []
                ordered[order] << ph
            else
                unordered << ph
            end
        end

        ordered << unordered
        ordered.flatten!

        ordered.inject({}) do |h, ph|
            name   = ph.keys.first
            plugin = ph.values.first

            if (ret = sane_env?( plugin )) != true
                deps = ''
                if !ret[:gem_errors].empty?
                    print_bad "[#{name}] The following plug-in dependencies aren't satisfied:"
                    ret[:gem_errors].each { |gem| print_bad "\t* #{gem}" }

                    deps = ret[:gem_errors].join( ' ' )
                    print_bad 'Try installing them by running:'
                    print_bad "\tgem install #{deps}"
                end

                fail Error::UnsatisfiedDependency,
                     "Plug-in dependencies not met: #{name} -- #{deps}"
            end

            h[name] = prep_opts( name, plugin, @framework.opts.plugins[name] )
            h
        end
    end

    # Checks whether or not the environment satisfies all plugin dependencies.
    #
    # @return   [TrueClass, Hash]
    #   `true` if the environment is sane, a hash with errors otherwise.
    def sane_env?( plugin )
        gem_errors = []

        plugin.gems.each do |gem|
            begin
                require gem
            rescue LoadError
                gem_errors << gem
            end
        end

        return { gem_errors: gem_errors } if !gem_errors.empty?
        true
    end

    def create( name, options = {} )
        self[name].new( @framework, options )
    end

    # Blocks until all plug-ins have finished executing.
    def block
        while @jobs.any?
            print_debug
            print_debug "Waiting on #{@jobs.size} plugins to finish:"
            print_debug job_names.join( ', ' )
            print_debug

            @jobs.delete_if { |j| !j.alive? }
            sleep 0.1
        end
        nil
    end

    def suspend
        @jobs.dup.each do |job|
            next if !job.alive?
            plugin = job[:instance]

            state.store( plugin.shortname,
                data:    plugin.suspend,
                options: plugin.options
            )

            job.kill
            @jobs.delete job
        end

        nil
    end

    def restore
        prepare.each do |name, options|
            @jobs << Thread.new do
                exception_jail( false ) do
                    if state.include? name
                        Thread.current[:instance] = create( name, state[name][:options] )
                        Thread.current[:instance].restore state[name][:data]
                    else
                        Thread.current[:instance] = create( name, options )
                        Thread.current[:instance].prepare
                    end

                    Thread.current[:instance].run
                    Thread.current[:instance].clean_up
                end
            end
        end

        return if @jobs.empty?

        print_status 'Waiting for plugins to settle...'
        sleep 1

        nil
    end

    # @return   [Bool]
    #   `false` if all plug-ins have finished executing, `true` otherwise.
    def busy?
        !!@jobs.find { |j| j.alive? }
    end

    # @return   [Array] Names of all running plug-ins.
    def job_names
        @jobs.map{ |j| j[:instance].shortname }
    end

    # @return   [Array<Thread>] All the running threads.
    def jobs
        @jobs
    end

    # Kills a plug-in by `name`.
    #
    # @param    [String]    name
    def kill( name )
        job = get( name )
        return true if job && job.kill
        false
    end

    def killall
        @jobs.each(&:kill)
        @jobs.clear
    end

    # Gets a running plug-in by name.
    #
    # @param    [String]    name
    #
    # @return   [Thread]
    def get( name )
        @jobs.each { |job| return job if job[:instance].shortname == name }
        nil
    end

    def state
        State.plugins
    end

    def data
        Data.plugins
    end

    def results
        data.results
    end

    def self.reset
        State.plugins.clear
        Data.plugins.clear
        remove_constants( NAMESPACE )
    end
    def reset
        killall
        clear
        self.class.reset
    end

end
end
end
