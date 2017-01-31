=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

# The namespace under which all plugins exist.
module Plugins
end

module Plugin

class Error < Arachni::Error
    class UnsatisfiedDependency < Error
    end
end

# Holds and manages the {Plugins}.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Manager < Arachni::Component::Manager
    include MonitorMixin

    # Namespace under which all plugins reside.
    NAMESPACE = Arachni::Plugins

    # Expressions matching default plugins.
    DEFAULT   = %w(defaults/*)

    # @param    [Arachni::Framework]    framework
    #   Framework instance.
    def initialize( framework )
        super( framework.options.paths.plugins, NAMESPACE )
        @framework = framework

        @jobs = {}
    end

    # Loads the default plugins.
    #
    # @see DEFAULT
    def load_default
        load DEFAULT
    end
    alias :load_defaults :load_default

    # @return   [Array<String>]
    #   Components to load, by name.
    def default
        parse DEFAULT
    end
    alias :defaults :default

    # Runs each plug-in in its own thread.
    #
    # @raise [Error::UnsatisfiedDependency]
    #   If the environment is {#sane_env? not sane}.
    def run
        print_status 'Preparing plugins...'

        schedule.each do |name, options|
            instance = create( name, options )

            exception_jail do
                instance.prepare
            end rescue next

            @jobs[name] = Thread.new do
                exception_jail( false ) do
                    Thread.current[:instance] = instance
                    Thread.current[:instance].run
                    Thread.current[:instance].clean_up
                end

                synchronize do
                    @jobs.delete name
                end
            end
        end

        print_status '... done.'
    end

    # @return   [Hash]
    #   Sorted plugins (by priority) with their prepared options.
    #
    # @raise [Error::UnsatisfiedDependency]
    #   If the environment is not {#sane_env? sane}.
    def schedule
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
        ordered.compact!

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

            h[name.to_sym] = prepare_options(
                name, plugin, @framework.options.plugins[name]
            )
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
        while busy?
            print_debug
            print_debug "Waiting on #{@jobs.size} plugins to finish:"
            print_debug job_names.join( ', ' )
            print_debug

            synchronize do
                @jobs.select! { |_ ,j| j.alive? }
            end

            sleep 0.1
        end
        nil
    end

    def suspend
        @jobs.dup.each do |name, job|
            next if !job.alive?
            plugin = job[:instance]

            state.store( name,
                data:    plugin.suspend,
                options: plugin.options
            )

            kill name
        end

        nil
    end

    def restore
        schedule.each do |name, options|
            @jobs[name] = Thread.new do
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

                    synchronize do
                        @jobs.delete name
                    end
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
        @jobs.any?
    end

    # @return   [Array]
    #   Names of all running plug-ins.
    def job_names
        @jobs.keys
    end

    # @return   [Hash{String=>Thread}]
    #   All the running threads.
    def jobs
        @jobs
    end

    # Kills a plug-in by `name`.
    #
    # @param    [String]    name
    def kill( name )
        synchronize do
            job = @jobs.delete( name.to_sym )
            return true if job && job.kill
        end
        false
    end

    def killall
        synchronize do
            @jobs.values.each(&:kill)
            @jobs.clear
            true
        end
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
