require_relative '../../../spec_helper'

require Arachni::Options.dir['lib'] + 'rpc/client/instance'
require Arachni::Options.dir['lib'] + 'rpc/server/instance'

describe Arachni::RPC::Server::Spider do
    before( :all ) do
        @opts = Arachni::Options.instance
        @token = 'secret!'

        @instances = []

        @get_instance = proc do |opts|
            opts ||= @opts

            port = random_port
            opts.rpc_port = port

            fork_em { Arachni::RPC::Server::Instance.new( opts, @token ) }
            sleep 1

            @instances << Arachni::RPC::Client::Instance.new( opts,
                "#{opts.rpc_address}:#{port}", @token
            )

            @instances.last
        end

        @utils = Arachni::Module::Utilities
        @instance = @get_instance.call
    end

    after( :all ){ @instances.each { |i| i.service.shutdown rescue nil } }

    context 'when using' do
        context 'multiple nodes' do
            it 'should perform a crawl using multiple nodes' do
                instance = @get_instance.call

                instance.service.scan(
                    url:            server_url_for( :spider ) + '/lots_of_paths',
                    spawns:         4,
                    http_req_limit: 5
                ).should be_true

                sleep 1 while instance.service.busy?

                instance.spider.sitemap.size.should == 10051
            end
        end
        context 'a single node' do
            it 'should perform a crawl' do
                instance = @get_instance.call

                instance.service.scan(
                    url: server_url_for( :spider ) + '/lots_of_paths',
                ).should be_true

                sleep 1 while instance.service.busy?

                instance.spider.sitemap.size.should == 10051
            end
        end
    end

end
