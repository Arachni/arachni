=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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

require 'singleton'
require 'eventmachine'

module Arachni
module Processes

class Manager
    include Singleton

    attr_reader :pids

    def initialize
        @pids = []
    end

    def <<( pid )
        @pids << pid
        Process.detach pid
        pid
    end

    def kill( pid )
        loop do
            begin
                Process.kill( 'KILL', pid )
            rescue Errno::ESRCH
                @pids.delete pid
                return true
            end
        end
    end

    def kill_many( pids )
        pids.each { |pid| kill pid }
    end

    def killall
        kill_many @pids.dup
        @pids.clear
    end

    def quite_fork( &block )
        self << fork( &discard_output( &block ) )
    end

    def kill_em
        ::EM.stop while ::EM.reactor_running? && sleep( 0.1 )
    rescue
        nil
    end

    def fork_em( *args, &block )
        self << ::EM.fork_reactor( *args, &discard_output( &block ) )
    end

    def discard_output( &block )
        proc do
            $stdout.reopen( '/dev/null', 'w' )
            $stderr.reopen( '/dev/null', 'w' )
            block.call
        end
    end

    def self.method_missing( sym, *args, &block )
        if instance.respond_to?( sym )
            instance.send( sym, *args, &block )
        elsif
        super( sym, *args, &block )
        end
    end

    def self.respond_to?( m )
        super( m ) || instance.respond_to?( m )
    end

end

end
end
