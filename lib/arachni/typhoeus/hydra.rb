=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

module Typhoeus
class Hydra

    attr_accessor :max_concurrency

    alias :old_run :run
    def run
        synchronize { old_run }
    end

    alias :old_queue :queue
    def queue( *args )
        synchronize { old_queue( *args ) }
    end

    private
    def locked?
        !!Thread.current[:locked]
    end

    def lock
        Thread.current[:locked] = true
    end

    def unlock
        Thread.current[:locked] = false
    end

    def synchronize( &block )
        if locked?
            block.call
        else
            lock
            (@mutex ||= Mutex.new).synchronize( &block )
            unlock
        end
    end

end
end
