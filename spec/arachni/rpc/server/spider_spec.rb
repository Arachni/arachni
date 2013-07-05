require 'spec_helper'

describe 'Arachni::RPC::Server::Spider' do

    context 'when using' do
        context 'multiple nodes' do
            it 'performs a crawl using multiple nodes' do
                #Arachni::Processes::Manager.preserve_output
                instance = instance_spawn

                #Arachni::Processes::Manager.discard_output
                instance.service.scan(
                    url:            web_server_url_for( :spider ) + '/lots_of_paths',
                    spawns:         4,
                    plugins:        %w(spider_hook)
                )

                sleep 1 while instance.service.busy?

                instances = instance.service.progress( with: :instances )['instances']

                instances.size.should == 5
                instances.each { |i| i['sitemap_size'].should > 1 }

                instance.framework.stats[:sitemap_size].should ==
                    instance.spider.local_sitemap.size

                sitemap = instance.spider.sitemap
                sitemap.size.should == 10051

                report = instance.service.report

                plugin_urls = report['plugins']['spider_hook'][:results].values.flatten
                plugin_urls.uniq.sort.should == sitemap.sort
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

                progress = instance.service.progress( with: :instances )

                progress['instances'].size.should == 0
                progress['stats']['sitemap_size'].should == 10051

                instance.spider.sitemap.size.should == progress['stats']['sitemap_size']
                instance.framework.stats[:sitemap_size].should ==
                    instance.spider.local_sitemap.size

                sitemap = instance.spider.sitemap
                sitemap.size.should == progress['stats']['sitemap_size']

                report = instance.service.report

                plugin_urls = report['plugins']['spider_hook'][:results].values.flatten
                plugin_urls.uniq.sort.should == sitemap.sort
            end
        end
    end

end
