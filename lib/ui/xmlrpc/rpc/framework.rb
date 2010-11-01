module Arachni

require Options.instance.dir['lib'] + 'framework'

module UI
module RPC

class Framework < Arachni::Framework
    alias :old_run :run

    def initialize( opts )
        super( opts )
    end

    def run
        @job = Thread.new { old_run }
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
