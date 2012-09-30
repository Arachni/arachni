require_relative '../../../spec_helper'

require Arachni::Options.instance.dir['lib'] + 'rpc/client/instance'
require Arachni::Options.instance.dir['lib'] + 'rpc/server/instance'

describe Arachni::RPC::Server::Instance do
    before( :all ) do
        @opts = Arachni::Options.instance
        @token = 'secret!'

        @get_instance = proc do |opts|
            opts ||= @opts
            port = random_port
            opts.rpc_port = port
            fork_em { Arachni::RPC::Server::Instance.new( opts, @token ) }
            sleep 1
            Arachni::RPC::Client::Instance.new( opts,
                "#{opts.rpc_address}:#{port}", @token
            )
        end

        @utils = Arachni::Module::Utilities
        @instance = @get_instance.call
    end

    describe '#service' do
        describe '#alive?' do
            it 'should return true' do
                @instance.service.alive?.should == true
            end
        end

        describe '#output' do
            it 'should return output messages' do
                @instance.service.output.should be_any
            end
        end

        describe '#shutdown' do
            it 'should shutdown the instance' do
                instance = @get_instance.call
                instance.service.shutdown.should be_true
                sleep 4
                raised = false
                begin
                    instance.service.alive?
                rescue Exception
                    raised = true
                end

                raised.should be_true
            end
        end
    end

    describe '#framework' do
        it 'should provide access to the framework' do
            @instance.framework.busy?.should be_false
        end
    end

    describe '#opts' do
        it 'should provide access to the options' do
            url = 'http://blah.com'
            @instance.opts.url = url
            @instance.opts.url.to_s.should == @utils.normalize_url( url )
        end
    end

    describe '#modules' do
        it 'should provide access to the module manager' do
            @instance.modules.available.sort.should == %w(test test2 test3).sort
        end
    end

    describe '#plugins' do
        it 'should provide access to the plugin manager' do
            @instance.plugins.available.sort.should == %w(wait bad distributable loop default with_options).sort
        end
    end
end
