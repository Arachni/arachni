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
                expect(page.url).to  eq(v.first['url'])
                expect(page.code).to eq(v.first['code'])
                expect(page.body).to eq(v.first['body'])

                expect(page.response.headers).to eq(v.first['headers'])

                oks += 1
            end

            if page.cookies.any?
                expect(page.cookies.size).to eq(1)
                cookie = v.select { |vector| vector['type'] == 'cookie' }.first
                expect(page.cookies.first.action).to eq(cookie['action'])
                expect(page.cookies.first.inputs).to eq(cookie['inputs'])

                expect(page.url).to  eq(cookie['action'])
                expect(page.code).to eq(200)
                expect(page.body).to eq('')

                oks += 1
            end

            if page.links.any?
                link = v.select { |vector| vector['type'] == 'link' }.first
                expect(page.links.first.action).to eq(link['action'])
                expect(page.links.first.inputs).to eq(link['inputs'])

                expect(page.url).to  eq(url)
                expect(page.code).to eq(200)
                expect(page.body).to eq('')

                oks += 1
            end

            if page.forms.any?
                form = v.select { |vector| vector['type'] == 'form' }.first
                expect(page.forms.first.action).to eq(form['action'])
                expect(page.forms.first.inputs).to eq(form['inputs'])

                expect(page.forms.first.immutables.include?( form['skip'].first )).to be_truthy

                expect(page.url).to  eq(url)
                expect(page.code).to eq(200)
                expect(page.body).to eq('')

                oks += 1
            end

            if page.headers.any?
                header = v.select { |vector| vector['type'] == 'header' }.first
                expect(page.headers.first.action).to eq(header['action'])
                expect(page.headers.first.inputs).to eq(header['inputs'])

                expect(page.url).to  eq(header['action'])
                expect(page.code).to eq(200)
                expect(page.body).to eq('')

                oks += 1
            end

            if page.jsons.any?
                json = v.select { |vector| vector['type'] == 'json' }.first
                expect(page.jsons.first.action).to eq(json['action'])
                expect(page.jsons.first.source).to eq(json['source'])
                expect(page.jsons.first.inputs).to eq({ 'name' => 'value' })

                expect(page.url).to  eq(json['action'])
                expect(page.code).to eq(200)
                expect(page.body).to eq('')

                oks += 1
            end

            if page.xmls.any?
                xml = v.select { |vector| vector['type'] == 'xml' }.first
                expect(page.xmls.first.action).to eq(xml['action'])
                expect(page.xmls.first.source).to eq(xml['source'])
                expect(page.xmls.first.inputs).to eq({
                    'forgot > username > text()' => 'admin'
                })

                expect(page.url).to  eq(xml['action'])
                expect(page.code).to eq(200)
                expect(page.body).to eq('')

                oks += 1
            end
        end

        expect(oks).to eq(7)
    end

    def run_test
        pages = []
        framework.on_page_audit { |page| pages << page }
        run

        check( pages )
    end

    context 'when setting the option' do
        describe ':vectors' do
            it 'forwards the given vectors to the framework to be audited' do
                options.plugins[component_name] = { 'vectors' => vectors.dup }
                run_test
            end
        end

        describe ':yaml_string' do
            it 'unserializes the given string and forward the given vectors to the framework to be audited' do
                options.plugins[component_name] = { 'yaml_string' => vectors.to_yaml }
                run_test
            end
        end

        describe ':yaml_file' do
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
