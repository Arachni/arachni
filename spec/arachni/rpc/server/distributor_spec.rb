require_relative '../../../spec_helper'

require 'timeout'
require Arachni::Options.instance.dir['lib'] + 'rpc/client/instance'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/instance'

require Arachni::Options.instance.dir['lib'] + 'rpc/server/distributor'

class Distributor
    include Arachni::RPC::Server::Framework::Distributor

    attr_reader :instances

    def initialize
        @opts = Arachni::Options.instance
        @instances = []
    end

    def <<( instance_h )
        @instances << instance_h
    end
end

describe Arachni::RPC::Server::Framework::Distributor do
    before( :all ) do
        @opts = Arachni::Options.instance
        @token = 'secret'

        @get_instance = proc do |opts|
            opts ||= @opts
            opts.rpc_port = random_port
            fork_em { Arachni::RPC::Server::Instance.new( opts, @token ) }
            sleep 1
            Arachni::RPC::Client::Instance.new( opts,
                "#{opts.rpc_address}:#{opts.rpc_port}", @token
            )
        end

        @distributor = Distributor.new
        2.times {
            @distributor <<  { 'url' => @get_instance.call.url, 'token' => @token }
        }
    end

    describe :map_slaves do
        it 'should asynchronously iterate over all slaves' do
            q = Queue.new

            foreach = proc { |instance, iter| instance.service.alive? { |res| iter.return( res ) } }
            after = proc { |res| q << res }

            @distributor.map_slaves( foreach, after )

            raised = false
            begin
                Timeout::timeout( 5 ) { q.pop.should == [true, true] }
            rescue Timeout::Error
                raised = true
            end
            raised.should be_false
        end
    end

    describe :each_slave do
        it 'should asynchronously iterate over all slaves' do
            q = Queue.new

            foreach = proc do |instance, iter|
                instance.service.alive? do |res|
                    q << res
                    iter.next
                end
            end
            @distributor.each_slave( &foreach )

            raised = false
            begin
                Timeout::timeout( 5 ) { [q.pop, q.pop].should == [true, true] }
            rescue Timeout::Error
                raised = true
            end
            raised.should be_false
        end
    end

    describe :slave_iterator do
        it 'should return an async iterator for the slave instances' do
            q = Queue.new

            foreach = proc do |instance, iter|
                q << instance['url']
                iter.next
            end
            @distributor.slave_iterator.each( &foreach )

            urls = @distributor.instances.map { |i| i['url'] }.sort

            raised = false
            begin
                Timeout::timeout( 5 ) { [q.pop, q.pop].sort.should == urls }
            rescue Timeout::Error
                raised = true
            end
            raised.should be_false
        end
    end

    describe :iterator_for do
        it 'should return an async iterator for the provided array' do
            q = Queue.new

            foreach = proc do |instance, iter|
                q << instance['url']
                iter.next
            end
            @distributor.iterator_for( @distributor.instances ).each( &foreach )

            urls = @distributor.instances.map { |i| i['url'] }.sort

            raised = false
            begin
                Timeout::timeout( 5 ) { [q.pop, q.pop].sort.should == urls }
            rescue Timeout::Error
                raised = true
            end
            raised.should be_false
        end
    end

    describe :distribute_elements do
        it 'should return an async iterator for the provided array' do
        end
    end

end
