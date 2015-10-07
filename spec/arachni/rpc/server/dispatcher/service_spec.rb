require 'spec_helper'

require "#{Arachni::Options.paths.lib}/rpc/server/dispatcher"

describe Arachni::RPC::Server::Dispatcher::Service do
    before( :all ) do
        Arachni::Options.paths.services = "#{fixtures_path}services/"

        @dispatcher = dispatcher_spawn

        @instance_count = 5
        @instance_count.times { @dispatcher.dispatch }
    end

    describe '#dispatcher' do
        it 'provides access to the parent Dispatcher' do
            expect(@dispatcher.echo.test_dispatcher).to be_truthy
        end
    end

    describe '#opts' do
        it 'provides access to the Dispatcher\'s options' do
            expect(@dispatcher.echo.test_opts).to be_truthy
        end
    end

    describe '#node' do
        it 'provides access to the Dispatcher\'s node' do
            expect(@dispatcher.echo.test_node).to be_truthy
        end
    end

    describe '#instances' do
        it 'provides access to the running instances' do
            expect(@dispatcher.echo.instances.map{ |i| i['pid'] }).to eq(@dispatcher.jobs.map{ |j| j['pid'] })
        end
    end

    describe '#map_instances' do
        it 'asynchronously maps all running instances' do
            expect(@dispatcher.echo.test_map_instances).to eq(
                Hash[@dispatcher.jobs.map { |j| [j['url'], j['token']] }]
            )
        end
    end

    describe '#each_instance' do
        it 'asynchronously iterates over all running instances' do
            @dispatcher.echo.test_each_instance
            urls = @dispatcher.jobs.map do |j|
                Arachni::RPC::Client::Instance.
                    new( Arachni::Options, j['url'], j['token'] ).options.url
            end

            expect(urls.size).to eq(@instance_count)
            urls.sort!

            1.upto( @instance_count ).each do |i|
                expect(urls[i-1]).to eq("http://stuff.com/#{i}")
            end
        end
    end

    describe '#defer' do
        it 'defers execution of the given block' do
            args = [1, 'stuff']
            expect(@dispatcher.echo.test_defer( *args )).to eq(args)
        end
    end

    describe '#run_asap' do
        it 'runs the given block as soon as possible' do
            args = [1, 'stuff']
            expect(@dispatcher.echo.test_run_asap( *args )).to eq(args)
        end
    end

    describe '#iterator_for' do
        it 'provides an asynchronous iterator' do
            expect(@dispatcher.echo.test_iterator_for).to be_truthy
        end
    end

    describe '#connect_to_dispatcher' do
        it 'connects to the a dispatcher by url' do
            expect(@dispatcher.echo.test_connect_to_dispatcher).to be_truthy
        end
    end

    describe '#connect_to_instance' do
        it 'connects to an instance' do
            instance = @dispatcher.jobs.first

            expect(@dispatcher.echo.test_connect_to_instance( instance )).to be_falsey
            expect(@dispatcher.echo.test_connect_to_instance( instance['url'], instance['token'] )).to be_falsey
            expect(@dispatcher.echo.test_connect_to_instance( url: instance['url'], token: instance['token'] )).to be_falsey
        end
    end

end
