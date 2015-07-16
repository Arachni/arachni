require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    def url
        Arachni::Utilities.normalize_url web_server_url_for( :framework )
    end

    before( :all ) do
        options.url = url
        options.scope.do_not_crawl
    end

    def vectors
        [
            {
                'type' => 'page',
                'url'  => url,
                'code' => 200,
                'headers' => { 'Content-Type '=> "text/html; charset=utf-8" },
                'body' => "HTML code goes here"
            },
            {
                'type'   => 'link',
                'action' => "#{url}link",
                'inputs' => { 'my_param' => 'my val' }
            },
            {
                'type'   => 'form',
                'method' => 'post',
                'action' => "#{url}form",
                'inputs' => {
                    'post_this' => 'HUA!',
                    'csrf'      => "my_csrf_token"
                },
                'skip' => %w(csrf)
            },
            {
                'type'   => 'cookie',
                'action' => "#{url}cookie",
                'inputs' => { 'session_id' => '43434234343sddsdsds' }
            },
            {
                'type'   => 'header',
                'action' => "#{url}header",
                'inputs' => { 'User-Agent' => "Blah/2" }
            },
            {
                'type'   => 'json',
                'action' => "#{url}json",
                'source' => '{"name": "value"}'
            },
            {
                'type'   => 'xml',
                'action' => "#{url}xml",
                'source' => '<forgot><username>admin</username></forgot>'
            }
        ]
    end

    def check( pages )
        v = vectors

        oks = 0
        pages.each do |page|
            next if page.code != 200

            if page.response.headers.any?
                page.url.should  == v.first['url']
                page.code.should == v.first['code']
                page.body.should == v.first['body']

                page.response.headers.should == v.first['headers']

                oks += 1
            end

            if page.cookies.any?
                page.cookies.size.should == 1
                cookie = v.select { |vector| vector['type'] == 'cookie' }.first
                page.cookies.first.action.should == cookie['action']
                page.cookies.first.inputs.should == cookie['inputs']

                page.url.should  == cookie['action']
                page.code.should == 200
                page.body.should == ''

                oks += 1
            end

            if page.links.any?
                link = v.select { |vector| vector['type'] == 'link' }.first
                page.links.first.action.should == link['action']
                page.links.first.inputs.should == link['inputs']

                page.url.should  == url
                page.code.should == 200
                page.body.should == ''

                oks += 1
            end

            if page.forms.any?
                form = v.select { |vector| vector['type'] == 'form' }.first
                page.forms.first.action.should == form['action']
                page.forms.first.inputs.should == form['inputs']

                page.forms.first.immutables.include?( form['skip'].first ).should be_true

                page.url.should  == url
                page.code.should == 200
                page.body.should == ''

                oks += 1
            end

            if page.headers.any?
                header = v.select { |vector| vector['type'] == 'header' }.first
                page.headers.first.action.should == header['action']
                page.headers.first.inputs.should == header['inputs']

                page.url.should  == header['action']
                page.code.should == 200
                page.body.should == ''

                oks += 1
            end

            if page.jsons.any?
                json = v.select { |vector| vector['type'] == 'json' }.first
                page.jsons.first.action.should == json['action']
                page.jsons.first.source.should == json['source']
                page.jsons.first.inputs.should == { 'name' => 'value' }

                page.url.should  == json['action']
                page.code.should == 200
                page.body.should == ''

                oks += 1
            end

            if page.xmls.any?
                xml = v.select { |vector| vector['type'] == 'xml' }.first
                page.xmls.first.action.should == xml['action']
                page.xmls.first.source.should == xml['source']
                page.xmls.first.inputs.should == {
                    'forgot > username > text()' => 'admin'
                }

                page.url.should  == xml['action']
                page.code.should == 200
                page.body.should == ''

                oks += 1
            end
        end

        oks.should == 7
    end

    def run_test
        pages = []
        framework.on_page_audit { |page| pages << page }
        run

        check( pages )
    end

    context 'when setting the option' do
        describe :vectors do
            it 'forwards the given vectors to the framework to be audited' do
                options.plugins[component_name] = { 'vectors' => vectors.dup }
                run_test
            end
        end

        describe :yaml_string do
            it 'unserializes the given string and forward the given vectors to the framework to be audited' do
                options.plugins[component_name] = { 'yaml_string' => vectors.to_yaml }
                run_test
            end
        end

        describe :yaml_file do
            it 'unserializes the given string and forward the given vectors to the framework to be audited' do
                File.open( 'yaml_file.yml', 'w' ){ |f| f.write( YAML.dump( vectors ) ) }

                options.plugins[component_name] = { 'yaml_file' => 'yaml_file.yml' }
                run_test

                File.delete( 'yaml_file.yml' )
            end

            it 'supports multiple documents in the same file' do
                File.open( 'yaml_file.yml', 'w' ){ |f| f.write( YAML.dump( vectors[1..-1] ) ) }
                File.open( 'yaml_file.yml', 'a' ){ |f| f.write( YAML.dump( vectors.first ) ) }

                options.plugins[component_name] = { 'yaml_file' => 'yaml_file.yml' }
                run_test

                File.delete( 'yaml_file.yml' )
            end

        end
    end
end
