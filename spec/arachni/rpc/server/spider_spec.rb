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
            it 'performs a crawl using multiple nodes' do
                instance = @get_instance.call

                instance.service.scan(
                    url:            server_url_for( :spider ) + '/lots_of_paths',
                    spawns:         4,
                    http_req_limit: 5,
                    plugins:        %w(spider_hook)
                )

                sleep 1 while instance.service.busy?
                instance.framework.clean_up

                instances = instance.service.progress( with: :instances )['instances']

                instances.size.should == 5
                instances.each { |i| i['sitemap_size'].should > 0 }

                sitemap = instance.spider.sitemap
                sitemap.size.should == 10051

                plugin_urls = instance.service.
                    report['plugins']['spider_hook'][:results].values.flatten
                sitemap.sort.should == plugin_urls.uniq.sort
            end
        end
        context 'a single node' do
            it 'performs a crawl' do
                instance = @get_instance.call

                instance.service.scan(
                    url:     server_url_for( :spider ) + '/lots_of_paths',
                    plugins: %w(spider_hook)
                )

                sleep 1 while instance.service.busy?

                instance.framework.clean_up

                progress = instance.service.progress( with: :instances )

                progress['instances'].size.should == 0
                progress['stats']['sitemap_size'].should == 10051

                instance.spider.sitemap.size.should == progress['stats']['sitemap_size']

                sitemap = instance.spider.sitemap
                sitemap.size.should == progress['stats']['sitemap_size']

                plugin_urls = instance.service.
                    report['plugins']['spider_hook'][:results].values.flatten
                sitemap.sort.should == plugin_urls.uniq.sort
            end
        end
    end

end
