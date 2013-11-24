require 'spec_helper'
require "#{Arachni::Options.dir['lib']}/rpc/server/dispatcher"

class Node < Arachni::RPC::Server::Dispatcher::Node

    def initialize( * )
        super

        methods.each do |m|
            next if method( m ).owner != Arachni::RPC::Server::Dispatcher::Node
            self.class.send :private, m
            self.class.send :public, m
        end

        @server = Arachni::RPC::Server::Base.new( @opts )
        @server.add_async_check do |method|
            # methods that expect a block are async
            method.parameters.flatten.include?( :block )
        end
        @server.add_handler( 'node', self )
        @server.run
    end

    def url
        "#{@opts.rpc_address}:#{@opts.rpc_port}"
    end

    def shutdown
        process_kill Process.pid
    end

    def connect_to_peer( url )
        self.class.connect_to_peer( url, @opts )
    end

    def self.connect_to_peer( url, opts )
        c = Arachni::RPC::Client::Base.new( opts, url )
        Arachni::RPC::RemoteObjectMapper.new( c, 'node' )
    end
end

describe Arachni::RPC::Server::Dispatcher::Node do
    before( :all ) do
        @opts = Arachni::Options.instance

        @get_node = proc do |c_port|
            opts = @opts
            port = c_port || available_port
            opts.rpc_port = port
            process_fork_em do
                Node.new( opts )
            end
            sleep 1
            Node.connect_to_peer( "#{opts.rpc_address}:#{port}", opts )
        end

        @node = @get_node.call
    end

    before( :each ) { @opts.rpc_external_address = nil }

    describe '#grid_member?' do
        context 'when the dispatcher is a grid member' do
            it 'should return true' do
                n = @get_node.call

                @opts.neighbour = n.url
                c = @get_node.call
                @opts.neighbour = nil
                sleep 4

                c.grid_member?.should be_true
            end
        end

        context 'when the dispatcher is not a grid member' do
            it 'should return false' do
                @node.grid_member?.should be_false
            end
        end
    end

    context 'when a previously unreachable neighbour comes back to life' do
        before( :all ) do
            @opts.node_ping_interval = 0.5
        end

        after( :all ) do
            @opts.node_ping_interval = nil
        end

        it 'gets re-added to the neighbours list' do
            n = @get_node.call

            port = available_port
            n.add_neighbour( 'localhost:' + port.to_s )

            sleep 4
            n.neighbours.should be_empty

            c = @get_node.call( port )

            sleep 4
            n.neighbours.should == [c.url]
            c.neighbours.should == [n.url]

            @opts.neighbour = nil
        end
    end

    context 'when a neighbour becomes unreachable' do
        before( :all ) do
            @opts.node_ping_interval = 0.5
        end

        after( :all ) do
            @opts.node_ping_interval = nil
        end

        it 'is removed' do
            n = @get_node.call
            c = @get_node.call

            n.add_neighbour( c.url )
            sleep 1
            c.neighbours.should == [n.url]
            n.neighbours.should == [c.url]

            begin
                n.shutdown
            rescue Exception
            end
            sleep 4
            c.neighbours.should be_empty
        end
    end

    context 'when initialised with a neighbour' do
        it 'adds that neighbour and reach convergence' do
            n = @get_node.call

            @opts.neighbour = n.url
            c = @get_node.call
            sleep 4
            c.neighbours.should == [n.url]
            n.neighbours.should == [c.url]

            d = @get_node.call
            sleep 4
            d.neighbours.sort.should == [n.url, c.url].sort
            c.neighbours.sort.should == [n.url, d.url].sort
            n.neighbours.sort.should == [c.url, d.url].sort

            @opts.neighbour = d.url
            e = @get_node.call
            sleep 4
            e.neighbours.sort.should == [n.url, c.url, d.url].sort
            d.neighbours.sort.should == [n.url, c.url, e.url].sort
            c.neighbours.sort.should == [n.url, d.url, e.url].sort
            n.neighbours.sort.should == [c.url, d.url, e.url].sort

            @opts.neighbour = nil
        end
    end

    describe '#add_neighbour' do
        before( :all ) do
            @n = @get_node.call
        end
        it 'adds a neighbour' do
            @node.add_neighbour( @n.url )
            sleep 0.5
            @node.neighbours.should == [@n.url]
            @n.neighbours.should == [@node.url]
        end
        context 'when propagate is set to true' do
            it 'announces the new neighbour to the existing neighbours' do
                n = @get_node.call
                @node.add_neighbour( n.url, true )
                sleep 0.5

                @node.neighbours.sort.should == [@n.url, n.url].sort
                @n.neighbours.sort.should == [@node.url, n.url].sort

                c = @get_node.call
                n.add_neighbour( c.url, true )
                sleep 0.5

                @node.neighbours.sort.should == [@n.url, n.url, c.url].sort
                @n.neighbours.sort.should == [@node.url, n.url, c.url].sort
                c.neighbours.sort.should == [@node.url, n.url, @n.url].sort

                d = @get_node.call
                d.add_neighbour( c.url, true )
                sleep 0.5

                @node.neighbours.sort.should == [d.url, @n.url, n.url, c.url].sort
                @n.neighbours.sort.should == [d.url, @node.url, n.url, c.url].sort
                c.neighbours.sort.should == [d.url, @node.url, n.url, @n.url].sort
                d.neighbours.sort.should == [c.url, @node.url, n.url, @n.url].sort
            end
        end
    end

    describe '#neighbours' do
        it 'returns an array of neighbours' do
            @node.neighbours.is_a?( Array ).should be_true
        end
    end

    describe '#neighbours_with_info' do
        it 'returns all neighbours accompanied by their node info' do
            @node.neighbours_with_info.size == @node.neighbours.size
            keys = @node.info.keys.sort
            @node.neighbours_with_info.each do |i|
                i.keys.sort.should == keys
            end
        end
    end

    describe '#info' do
        it 'returns node info' do
            @opts.pipe_id = 'pipe_id'
            @opts.weight = 10
            @opts.nickname = 'blah'
            @opts.cost = 12

            n = @get_node.call
            info = n.info

            info['url'].should == n.url
            info['pipe_id'].should == @opts.pipe_id
            info['weight'].should == @opts.weight
            info['nickname'].should == @opts.nickname
            info['cost'].should == @opts.cost
        end

        context 'when Options#rpc_external_address has been set' do
            it 'advertises that address' do
                @opts.rpc_external_address = '9.9.9.9'
                @get_node.call.info['url'].should start_with @opts.rpc_external_address
            end
        end
    end

    describe '#alive?' do
        it 'returns true' do
            @get_node.call.alive?.should be_true
        end
    end
end
