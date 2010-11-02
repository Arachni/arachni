module Arachni

require Options.instance.dir['lib'] + 'framework'

module UI
module RPC

=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

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

    def run
        @job = Thread.new {
            exception_jail { old_run }
        }
        return true
    end

    def pause
    end

    def resume
    end

    def abort
        @job.kill
        return true
    end

    def busy?
        return false if !@job
        return @job.alive?
    end

    def report
        return false if !@job
        return audit_store( true ).to_h.dup
    end

end

end
end
end
