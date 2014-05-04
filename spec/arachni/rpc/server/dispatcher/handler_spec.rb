require 'spec_helper'

require "#{Arachni::Options.paths.lib}/rpc/server/dispatcher"

describe Arachni::RPC::Server::Dispatcher::Handler do
    before( :all ) do
        Arachni::Options.paths.rpcd_handlers = "#{fixtures_path}rpcd_handlers/"

        @dispatcher = dispatcher_spawn

        @instance_count = 5
        @instance_count.times { @dispatcher.dispatch }
    end

    describe '#dispatcher' do
        it 'provides access to the parent Dispatcher' do
            @dispatcher.echo.test_dispatcher.should be_true
        end
    end

    describe '#opts' do
        it 'provides access to the Dispatcher\'s options' do
            @dispatcher.echo.test_opts.should be_true
        end
    end

    describe '#node' do
        it 'provides access to the Dispatcher\'s node' do
            @dispatcher.echo.test_node.should be_true
        end
    end

    describe '#instances' do
        it 'provides access to the running instances' do
            @dispatcher.echo.instances.map{ |i| i['pid'] }.should == @dispatcher.jobs.map{ |j| j['pid'] }
        end
    end

    describe '#map_instances' do
        it 'asynchronously maps all running instances' do
            @dispatcher.echo.test_map_instances.should ==
                Hash[@dispatcher.jobs.map { |j| [j['url'], j['token']] }]
        end
    end

    describe '#each_instance' do
        it 'asynchronously iterates over all running instances' do
            @dispatcher.echo.test_each_instance
            urls = @dispatcher.jobs.map do |j|
                Arachni::RPC::Client::Instance.
                    new( Arachni::Options, j['url'], j['token'] ).options.url
            end

            urls.size.should == @instance_count
            urls.sort!

            1.upto( @instance_count ).each do |i|
                urls[i-1].should == "http://stuff.com/#{i}"
            end
        end
    end

    describe '#defer' do
        it 'defers execution of the given block' do
            args = [1, 'stuff']
            @dispatcher.echo.test_defer( *args ).should == args
        end
    end

    describe '#run_asap' do
        it 'runs the given block as soon as possible' do
            args = [1, 'stuff']
            @dispatcher.echo.test_run_asap( *args ).should == args
        end
    end

    describe '#iterator_for' do
        it 'provides an asynchronous iterator' do
            @dispatcher.echo.test_iterator_for.should be_true
        end
    end

    describe '#connect_to_dispatcher' do
        it 'connects to the a dispatcher by url' do
            @dispatcher.echo.test_connect_to_dispatcher.should be_true
        end
    end

    describe '#connect_to_instance' do
        it 'connects to an instance' do
            instance = @dispatcher.jobs.first

            @dispatcher.echo.test_connect_to_instance( instance ).should be_false
            @dispatcher.echo.test_connect_to_instance( instance['url'], instance['token'] ).should be_false
            @dispatcher.echo.test_connect_to_instance( url: instance['url'], token: instance['token'] ).should be_false
        end
    end

end
