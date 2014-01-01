=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

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
