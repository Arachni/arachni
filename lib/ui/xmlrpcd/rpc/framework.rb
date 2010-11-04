=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

require Options.instance.dir['lib'] + 'framework'

module UI
module RPCD

#
# Extends the Framework adding XML-RPC specific functionality
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Framework < Arachni::Framework

    #
    # Our run() method needs to run the parent's run() method in
    # a separate thread.
    #
    alias :old_run :run
    alias :old_stats :stats
    alias :old_pause :pause
    alias :old_paused? :paused?
    alias :old_resume :resume
    alias :old_lsmod :lsmod

    private :old_run, :old_stats, :old_pause, :old_paused?, :old_resume, :lsmod

    #
    # for some reason XMLRPC's add_handler() doesn't see these methods
    # even though they were public in the parent, so we need to re-declare them ;)
    #
    public :pause, :paused?, :resume, :lsmod, :lsrep

    def initialize( opts )
        super( opts )
    end

    def pause
        old_pause
    end

    def paused?
        old_paused?
    end

    def resume
        old_resume
    end

    def stats
        old_stats
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

    #
    # Aborts the running audit.
    #
    def abort
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
    # Returns the results of the audit.
    #
    # @return   [Hash]
    #
    def report
        return false if !@job
        return audit_store( true ).to_h.dup
    end

    def auditstore
        return false if !@job
        return YAML.dump( audit_store( true ).deep_clone )
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
    # Checks whether the framework is in debug mode
    #
    def debug?
        @@debug
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

    #
    # Checks whether the framework is in debug mode
    #
    def verbose?
        @@verbose
    end


end

end
end
end
