require 'spec_helper'
require "#{Arachni::Options.paths.lib}/rpc/server/dispatcher"

describe Arachni::RPC::Server::Dispatcher::Node do
    before( :all ) do
        Arachni::Options.paths.executables = "#{fixtures_path}executables/"

        @get_node = proc do |port = available_port|
            Arachni::Options.rpc.server_port = port

            Arachni::Processes::Manager.spawn( :node )

            sleep 1

            c = Arachni::RPC::Client::Base.new(
                Arachni::Options,
                "#{Arachni::Options.rpc.server_address}:#{port}"
            )
            Arachni::RPC::RemoteObjectMapper.new( c, 'node' )
        end

        @node = @get_node.call
    end
    before( :each ) { options.dispatcher.external_address = nil }

    let(:options) { Arachni::Options }

    describe '#grid_member?' do
        context 'when the dispatcher is a grid member' do
            it 'should return true' do
                n = @get_node.call

                options.dispatcher.neighbour = n.url
                c = @get_node.call
                options.dispatcher.neighbour = nil
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
            options.dispatcher.node_ping_interval = 0.5
        end

        after( :all ) do
            options.dispatcher.node_ping_interval = nil
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

            options.dispatcher.neighbour = nil
        end
    end

    context 'when a neighbour becomes unreachable' do
        before( :all ) do
            options.dispatcher.node_ping_interval = 0.5
        end

        after( :all ) do
            options.dispatcher.node_ping_interval = nil
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

            options.dispatcher.neighbour = n.url
            c = @get_node.call
            sleep 4
            c.neighbours.should == [n.url]
            n.neighbours.should == [c.url]

            d = @get_node.call
            sleep 4
            d.neighbours.sort.should == [n.url, c.url].sort
            c.neighbours.sort.should == [n.url, d.url].sort
            n.neighbours.sort.should == [c.url, d.url].sort

            options.dispatcher.neighbour = d.url
            e = @get_node.call
            sleep 4
            e.neighbours.sort.should == [n.url, c.url, d.url].sort
            d.neighbours.sort.should == [n.url, c.url, e.url].sort
            c.neighbours.sort.should == [n.url, d.url, e.url].sort
            n.neighbours.sort.should == [c.url, d.url, e.url].sort

            options.dispatcher.neighbour = nil
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
            options.dispatcher.node_pipe_id = 'dispatcher_node_pipe_id'
            options.dispatcher.node_weight = 10
            options.dispatcher.node_nickname = 'blah'
            options.dispatcher.node_cost = 12

            n = @get_node.call
            info = n.info

            info['url'].should == n.url
            info['pipe_id'].should == options.dispatcher.node_pipe_id
            info['weight'].should == options.dispatcher.node_weight
            info['nickname'].should == options.dispatcher.node_nickname
            info['cost'].should == options.dispatcher.node_cost
        end

        context 'when Options#dispatcher_external_address has been set' do
            it 'advertises that address' do
                options.dispatcher.external_address = '9.9.9.9'
                @get_node.call.info['url'].should start_with options.dispatcher.external_address
            end
        end
    end

    describe '#alive?' do
        it 'returns true' do
            @get_node.call.alive?.should be_true
        end
    end
end
