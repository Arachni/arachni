require 'spec_helper'
require "#{Arachni::Options.paths.lib}/rpc/server/dispatcher"

describe Arachni::RPC::Server::Dispatcher::Node do
    before( :all ) do
        Arachni::Options.paths.executables = "#{fixtures_path}executables/"

        Arachni::Reactor.global.run_in_thread if !Arachni::Reactor.global.running?

        @get_node = proc do |port = available_port|
            Arachni::Options.rpc.server_port = port

            Arachni::Processes::Manager.spawn( :node )

            c = Arachni::RPC::Client::Base.new(
                Arachni::Options,
                "#{Arachni::Options.rpc.server_address}:#{port}"
            )
            c = Arachni::RPC::Proxy.new( c, 'node' )

            begin
                c.alive?
            rescue Arachni::RPC::Exceptions::ConnectionError
                sleep 0.1
                retry
            end

            c
        end

        @node = @get_node.call
    end
    before( :each ) { Arachni::Options.dispatcher.external_address = nil }

    let(:options) { Arachni::Options }

    describe '#grid_member?' do
        context 'when the dispatcher is a grid member' do
            it 'should return true' do
                n = @get_node.call

                options.dispatcher.neighbour = n.url
                c = @get_node.call
                options.dispatcher.neighbour = nil
                sleep 4

                expect(c.grid_member?).to be_truthy
            end
        end

        context 'when the dispatcher is not a grid member' do
            it 'should return false' do
                expect(@node.grid_member?).to be_falsey
            end
        end
    end

    context 'when a previously unreachable neighbour comes back to life' do
        before( :all ) do
            Arachni::Options.dispatcher.node_ping_interval = 0.5
        end

        after( :all ) do
            Arachni::Options.dispatcher.node_ping_interval = nil
        end

        it 'gets re-added to the neighbours list' do
            n = @get_node.call

            port = available_port
            n.add_neighbour( '127.0.0.1:' + port.to_s )

            sleep 4
            expect(n.neighbours).to be_empty

            c = @get_node.call( port )

            sleep 4
            expect(n.neighbours).to eq([c.url])
            expect(c.neighbours).to eq([n.url])

            options.dispatcher.neighbour = nil
        end
    end

    context 'when a neighbour becomes unreachable' do
        before( :all ) do
            Arachni::Options.dispatcher.node_ping_interval = 0.5
        end

        after( :all ) do
            Arachni::Options.dispatcher.node_ping_interval = nil
        end

        it 'is removed' do
            n = @get_node.call
            c = @get_node.call

            n.add_neighbour( c.url )
            sleep 1

            expect(c.neighbours).to eq([n.url])
            expect(n.neighbours).to eq([c.url])

            n.shutdown rescue Arachni::RPC::Exceptions::ConnectionError

            sleep 4

            expect(c.neighbours).to be_empty
        end
    end

    context 'when initialised with a neighbour' do
        it 'adds that neighbour and reach convergence' do
            n = @get_node.call

            options.dispatcher.neighbour = n.url
            c = @get_node.call
            sleep 4
            expect(c.neighbours).to eq([n.url])
            expect(n.neighbours).to eq([c.url])

            d = @get_node.call
            sleep 4
            expect(d.neighbours.sort).to eq([n.url, c.url].sort)
            expect(c.neighbours.sort).to eq([n.url, d.url].sort)
            expect(n.neighbours.sort).to eq([c.url, d.url].sort)

            options.dispatcher.neighbour = d.url
            e = @get_node.call
            sleep 4
            expect(e.neighbours.sort).to eq([n.url, c.url, d.url].sort)
            expect(d.neighbours.sort).to eq([n.url, c.url, e.url].sort)
            expect(c.neighbours.sort).to eq([n.url, d.url, e.url].sort)
            expect(n.neighbours.sort).to eq([c.url, d.url, e.url].sort)

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
            expect(@node.neighbours).to eq([@n.url])
            expect(@n.neighbours).to eq([@node.url])
        end
        context 'when propagate is set to true' do
            it 'announces the new neighbour to the existing neighbours' do
                n = @get_node.call
                @node.add_neighbour( n.url, true )
                sleep 0.5

                expect(@node.neighbours.sort).to eq([@n.url, n.url].sort)
                expect(@n.neighbours.sort).to eq([@node.url, n.url].sort)

                c = @get_node.call
                n.add_neighbour( c.url, true )
                sleep 0.5

                expect(@node.neighbours.sort).to eq([@n.url, n.url, c.url].sort)
                expect(@n.neighbours.sort).to eq([@node.url, n.url, c.url].sort)
                expect(c.neighbours.sort).to eq([@node.url, n.url, @n.url].sort)

                d = @get_node.call
                d.add_neighbour( c.url, true )
                sleep 0.5

                expect(@node.neighbours.sort).to eq([d.url, @n.url, n.url, c.url].sort)
                expect(@n.neighbours.sort).to eq([d.url, @node.url, n.url, c.url].sort)
                expect(c.neighbours.sort).to eq([d.url, @node.url, n.url, @n.url].sort)
                expect(d.neighbours.sort).to eq([c.url, @node.url, n.url, @n.url].sort)
            end
        end
    end

    describe '#neighbours' do
        it 'returns an array of neighbours' do
            expect(@node.neighbours.is_a?( Array )).to be_truthy
        end
    end

    describe '#neighbours_with_info' do
        it 'returns all neighbours accompanied by their node info' do
            @node.neighbours_with_info.size == @node.neighbours.size
            keys = @node.info.keys.sort
            @node.neighbours_with_info.each do |i|
                expect(i.keys.sort).to eq(keys)
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

            expect(info['url']).to eq(n.url)
            expect(info['pipe_id']).to eq(options.dispatcher.node_pipe_id)
            expect(info['weight']).to eq(options.dispatcher.node_weight)
            expect(info['nickname']).to eq(options.dispatcher.node_nickname)
            expect(info['cost']).to eq(options.dispatcher.node_cost)
        end

        context 'when Options#dispatcher_external_address has been set' do
            it 'advertises that address' do
                options.dispatcher.external_address = '9.9.9.9'
                expect(@get_node.call.info['url']).to start_with options.dispatcher.external_address
            end
        end
    end

    describe '#alive?' do
        it 'returns true' do
            expect(@get_node.call.alive?).to be_truthy
        end
    end
end
