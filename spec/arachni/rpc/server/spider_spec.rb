require 'spec_helper'

describe Arachni::RPC::Server::Spider do

    context 'when using' do
        context 'multiple nodes' do
            it 'performs a crawl using multiple nodes' do
                instance = instance_spawn

                instance.service.scan(
                    url:            web_server_url_for( :spider ) + '/lots_of_paths',
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
                instance = instance_spawn

                instance.service.scan(
                    url:     web_server_url_for( :spider ) + '/lots_of_paths',
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
