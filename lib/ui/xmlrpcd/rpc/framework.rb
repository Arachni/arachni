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

    private :old_run

    #
    # for some reason XMLRPC's add_handler() doesn't see these methods
    # even though they were public in the parent, so we need to re-declare them ;)
    #
    public :pause, :paused?, :resume, :lsmod

    def initialize( opts )
        super( opts )
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
