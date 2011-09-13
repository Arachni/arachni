=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

require Options.instance.dir['lib'] + 'framework'
require Options.instance.dir['lib'] + 'rpc/server/module/manager'
require Options.instance.dir['lib'] + 'rpc/server/plugin/manager'

module RPC
module Server

#
# Extends the Framework adding BrB-RPC specific functionality
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class Framework < Arachni::Framework

    #
    # Our run() method needs to run the parent's run() method in
    # a separate thread.
    #
    alias :old_run :run

    # make this inherited methods visible again
    private :old_run, :stats, :pause!, :paused?, :resume!, :lsmod, :modules, :lsplug, :clean_up!
    public  :stats, :pause!, :paused?, :resume!, :lsmod, :modules, :lsplug, :clean_up!

    #
    # Aborts the running audit.
    #
    def abort!
        @job.kill
        return true
    end

    #
    # Checks to see if an audit is running.
    #
    # @return   [Bool]
    #
    def busy?
        return false if !@job
        return @job.alive?
    end

    #
    # Checks whether the framework is in debug mode
    #
    def debug?
        @@debug
    end

    #
    # Checks whether the framework is in debug mode
    #
    def verbose?
        @@verbose
    end


    #
    # some BrBRPC libraries of other languages map remote objects to local objects
    # creating an invalid syntax situation since the aforementioned languages
    # may not allow "?" or "!" in method names.
    #
    # so we alias these methods to make it easier on 3rd party developers.
    #
    alias :pause :pause!
    alias :is_paused :paused?
    alias :resume :resume!
    alias :clean_up :clean_up!
    alias :is_busy :busy?
    alias :is_debug :debug?
    alias :is_verbose :verbose?

    def initialize( opts )
        super( opts )
        @modules = Arachni::RPC::Server::Module::Manager.new( opts )
        @plugins = Arachni::RPC::Server::Plugin::Manager.new( self )
    end

    #
    # Returns an array of hashes with information
    # about all available reports
    #
    # @return    [Array<Hash>]
    #
    def lsplug

        plug_info = []

        @plugins.available( ).each {
            |plugin|

            info = @plugins[plugin].info

            info[:plug_name]   = plugin
            info[:path]        = @plugins.name_to_path( plugin )

            info[:options] = [info[:options]].flatten.compact.map {
                |opt|
                opt_h = opt.to_h
                opt_h['default'] = '' if opt_h['default'].nil?
                opt_h['type']    = opt.type
                opt_h
            }

            plug_info << info
        }

        @plugins.clear( )

        return plug_info
    end


    #
    # Starts the audit.
    #
    # The audit is started in a new thread to avoid service blocking.
    #
    def run
        @job = Thread.new {
            exception_jail { old_run }
        }
        return true
    end

    def get_plugin_store
        @plugin_store
    end

    def set_plugin_store( plugin_store )
        @plugin_store = plugin_store
    end

    #
    # Returns the results of the audit.
    #
    # @return   [YAML]  YAML dump of the results hash
    #
    def report
        exception_jail {
            return false if !@job

            store =  audit_store( true )
            store.framework = ''
            return YAML.dump( store.to_h.dup )
        }
    end

    #
    # Returns the results of the audit as a serialized AuditStore object.
    #
    # @return   [YAML]  YAML dump of the AuditStore
    #
    def auditstore
        exception_jail {
            return false if !@job

            store =  audit_store( true )
            store.framework = nil

            return YAML.dump( store )
        }
    end

    #
    # Enables debugging output
    #
    def debug_on
        @@debug = true
    end

    #
    # Disables debugging output
    #
    def debug_off
        @@debug = false
    end

    #
    # Enables debugging output
    #
    def verbose_on
        @@verbose = true
    end

    #
    # Disables debugging output
    #
    def verbose_off
        @@verbose = false
    end

end

end
end
end
