require 'spec_helper'
require 'fileutils'

describe Arachni::RPC::Client::Dispatcher do
    before( :all ) do
        @handler_lib = Arachni::Options.paths.services
        FileUtils.cp( "#{fixtures_path}/services/echo.rb", @handler_lib )

        @dispatcher = dispatcher_light_spawn
    end

    after( :all ) { FileUtils.rm( "#{@handler_lib}/echo.rb" ) }

    it 'maps the remote handlers to local objects' do
        args = [ 'stuff', 'here', { 'blah' => true } ]
        @dispatcher.echo.echo( *args ).should == args
    end

    describe '#node' do
        it 'provides access to the node data' do
            @dispatcher.node.info.is_a?( Hash ).should be_true
        end
    end

end
