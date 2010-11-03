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
module RPC

#
# Extends the Framework adding XML-RPC specific functionality
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class Framework < Arachni::Framework
    alias :old_run :run

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
    # To be implemented...
    #
    def pause
    end

    #
    # To be implemented...
    #
    def resume
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

end

end
end
end
