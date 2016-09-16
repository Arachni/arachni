require 'spec_helper'
require "#{Arachni::Options.paths.lib}/rest/server"

describe Arachni::Rest::Server do
    include RequestHelpers

    let(:scan_url) { @scan_url }
    let(:url) { tpl_url % id }
    let(:id) { @id }
    let(:non_existent_id) { 'stuff' }

    before do
        @scan_url = web_server_url_for(:framework)
        reset_options
    end

    def create_scan
        post '/scans',
             url:             scan_url,
             checks:          ['test'],
             audit:           {
                 elements:    [:links, :forms, :cookies]
             },
             browser_cluster: {
                 pool_size: 0
             }
        response_data['id']
    end

    context 'supports compressing as' do
        ['deflate','gzip', 'deflate,gzip','gzip,deflate'].each do |compression_method|

            it compression_method do
                get '/', {}, { 'HTTP_ACCEPT_ENCODING' => compression_method }
                expect( response.headers['Content-Encoding'] ).to eq compression_method.split( ',' ).first
            end

        end
    end

    context 'when the client does not support compression' do
        it 'does not compress the response' do
            get '/'
            expect(response.headers['Content-Encoding']).to be_nil
        end
    end

    context 'when authentication' do
        let(:username) { nil }
        let(:password) { nil }
        let(:userpwd) { "#{username}:#{password}" }
        let(:url) { "http://localhost:#{Arachni::Options.rpc.server_port}/scans" }

        before do
            Arachni::Options.datastore['username'] = username
            Arachni::Options.datastore['password'] = password

            Arachni::Options.rpc.server_port = Arachni::Utilities.available_port
            Arachni::Processes::Manager.spawn( :rest_service )

            sleep 0.1 while Typhoeus.get( url ).code == 0
        end

        after do
            Arachni::Processes::Manager.killall
        end

        context 'username' do
            let(:username) { 'username' }

            context 'is configured' do
                it 'requires authentication' do
                    expect(Typhoeus.get( url ).code).to eq 401
                    expect(Typhoeus.get( url, userpwd: userpwd ).code).to eq 200
                end
            end
        end

        context 'password' do
            let(:password) { 'password' }

            context 'is configured' do
                it 'requires authentication' do
                    expect(Typhoeus.get( url ).code).to eq 401
                    expect(Typhoeus.get( url, userpwd: userpwd ).code).to eq 200
                end
            end
        end
    end

    describe 'SSL options', if: !Arachni.jruby? && !Arachni.windows? do
        let(:ssl_key) { nil }
        let(:ssl_cert) { nil }
        let(:ssl_ca) { nil }
        let(:url) { "http://localhost:#{Arachni::Options.rpc.server_port}/scans" }
        let(:https_url) { "https://localhost:#{Arachni::Options.rpc.server_port}/scans" }

        before do
            Arachni::Options.rpc.ssl_ca                 = ssl_ca
            Arachni::Options.rpc.server_ssl_private_key = ssl_key
            Arachni::Options.rpc.server_ssl_certificate = ssl_cert

            Arachni::Options.rpc.server_port = Arachni::Utilities.available_port
            Arachni::Processes::Manager.spawn( :rest_service )

            sleep 0.1 while Typhoeus.get( url ).return_code == :couldnt_connect
        end

        after do
            Arachni::Processes::Manager.killall
        end

        describe 'when key and certificate is given' do
            let(:ssl_key) { "#{support_path}/pems/server/key.pem" }
            let(:ssl_cert) { "#{support_path}/pems/server/cert.pem" }

            describe 'when no CA is given' do
                it 'disables peer verification' do
                    expect(Typhoeus.get( https_url, ssl_verifypeer: false ).code).to eq 200
                end
            end

            describe 'a CA is given' do
                let(:ssl_ca) { "#{support_path}/pems/cacert.pem" }

                it 'enables peer verification' do
                    expect(Typhoeus.get( https_url, ssl_verifypeer: false ).code).to eq 0

                    expect(Typhoeus.get(
                        https_url,
                        ssl_verifypeer: true,
                        sslcert:        "#{support_path}/pems/client/cert.pem",
                        sslkey:         "#{support_path}/pems/client/key.pem",
                        cainfo:         ssl_ca
                    ).code).to eq 200
                end
            end
        end

        describe 'when only key is given' do
            let(:ssl_key) { "#{support_path}/pems/server/key.pem" }

            it 'does not enable SSL' do
                expect(Typhoeus.get( url ).code).to eq 200
            end
        end

        describe 'when only cert is given' do
            let(:ssl_cert) { "#{support_path}/pems/server/cert.pem" }

            it 'does not enable SSL' do
                expect(Typhoeus.get( url ).code).to eq 200
            end
        end
    end

    describe 'GET /scans' do
        before do
            @ids = []
            2.times do
                @ids << create_scan
            end
        end

        let(:tpl_url) { '/scans' }

        it 'lists ids for all instances' do
            get url

            @ids.each do |id|
                expect(response_data[id]).to eq({})
            end
        end
    end

    describe 'POST /scans' do
        let(:tpl_url) { '/scans' }

        it 'creates a scan' do
            post url,
                 url: scan_url,
                 browser_cluster: {
                     pool_size: 0
                 }

            expect(response_code).to eq 200
        end

        context 'when given invalid options' do
            it 'returns a 500' do
                post url, stuff: scan_url

                expect(response_code).to eq 500
                expect(response_data).to include 'error'
                expect(response_data).to include 'backtrace'
            end

            it 'does not list the instance on the index' do
                get '/scans'
                ids = response_data.keys

                post url, stuff: scan_url

                get '/scans'
                expect(response_data.keys - ids).to be_empty
            end
        end
    end

    describe 'GET /scans/:id' do
        let(:tpl_url) { '/scans/%s' }

        before do
            @id = create_scan
        end

        it 'gets progress info' do
            loop do
                get url
                break if !response_data['busy']
                sleep 0.5
            end

            %w(errors status busy messages statistics).each do |key|
                expect(response_data).to include key
            end

            %w(issues sitemap statistics).each do |key|
                expect(response_data).to be_any
            end
        end

        context 'when a session is maintained' do
            it 'only returns new issues'
            it 'only returns new errors'
            it 'only returns new sitemap entries'
        end

        context 'when a session is not maintained' do
            it 'always returns all issues'
            it 'always returns all errors'
            it 'always returns all sitemap entries'
        end

        context 'when passed a non-existent id' do
            let(:id) { non_existent_id }

            it 'returns 404' do
                get url
                expect(response_code).to eq 404
            end
        end
    end

    describe 'GET /scans/:id/summary' do
        let(:tpl_url) { '/scans/%s/summary' }

        before do
            @id = create_scan
        end

        it 'does not include issues and sitemap' do
            loop do
                get url
                break if !response_data['busy']
                sleep 0.5
            end

            %w(status busy messages statistics).each do |key|
                expect(response_data).to include key
            end

            %w(issues sitemap errors).each do |key|
                expect(response_data).to_not include key
            end
        end

        context 'when passed a non-existent id' do
            let(:id) { non_existent_id }

            it 'returns 404' do
                get url
                expect(response_code).to eq 404
            end
        end
    end

    describe 'GET /scans/:id/report.:format' do
        let(:tpl_url) { "/scans/%s/report.#{format}" }

        describe 'without format' do
            let(:tpl_url) { '/scans/%s/report' }

            before do
                @id = create_scan
            end

            it 'returns scan report as JSON' do
                get url

                %w(version options issues sitemap plugins start_datetime
                finish_datetime).each do |key|
                    expect(response_data).to include key
                end
            end

            it 'has content-type application/json' do
                get url
                expect(last_response.headers['content-type']).to eq 'application/json'
            end

            context 'when passed a non-existent id' do
                let(:id) { non_existent_id }

                it 'returns 404' do
                    get url
                    expect(response_code).to eq 404
                end
            end
        end

        describe 'json' do
            let(:format) { 'json' }

            before do
                @id = create_scan
            end

            it 'returns scan report as JSON' do
                get url

                %w(version options issues sitemap plugins start_datetime
                finish_datetime).each do |key|
                    expect(response_data).to include key
                end
            end

            it 'has content-type application/json' do
                get url
                expect(last_response.headers['content-type']).to eq 'application/json'
            end

            context 'when passed a non-existent id' do
                let(:id) { non_existent_id }

                it 'returns 404' do
                    get url
                    expect(response_code).to eq 404
                end
            end
        end

        describe 'xml' do
            let(:format) { 'xml' }

            before do
                @id = create_scan
            end

            it 'returns scan report as XML' do
                get url

                %w(version options issues sitemap plugins start_datetime
                finish_datetime).each do |key|
                    expect(
                        response_body.include?( "<#{key}>") ||
                            response_body.include?( "<#{key}/>")
                    ).to be_truthy
                end
            end

            it 'has content-type application/xml' do
                get url
                expect(last_response.headers['content-type']).to eq 'application/xml;charset=utf-8'
            end

            context 'when passed a non-existent id' do
                let(:id) { non_existent_id }

                it 'returns 404' do
                    get url
                    expect(response_code).to eq 404
                end
            end
        end

        describe 'yaml' do
            let(:format) { 'yaml' }

            before do
                @id = create_scan
            end

            it 'returns scan report as YAML' do
                get url

                data = YAML.load( response_body )
                %w(version options issues sitemap plugins start_datetime
                finish_datetime).each do |key|
                    expect(data).to include key.to_sym
                end
            end

            it 'has content-type text/yaml' do
                get url
                expect(last_response.headers['content-type']).to eq 'text/yaml;charset=utf-8'
            end

            context 'when passed a non-existent id' do
                let(:id) { non_existent_id }

                it 'returns 404' do
                    get url
                    expect(response_code).to eq 404
                end
            end
        end

        describe 'html.zip' do
            let(:format) { 'html.zip' }

            before do
                @id = create_scan
            end

            it 'returns scan report as a zipped HTML' do
                get url

                expect(response_body).to start_with 'PK'
            end

            it 'has content-type application/zip' do
                get url
                expect(last_response.headers['content-type']).to eq 'application/zip'
            end

            context 'when passed a non-existent id' do
                let(:id) { non_existent_id }

                it 'returns 404' do
                    get url
                    expect(response_code).to eq 404
                end
            end
        end

        describe 'invalid format' do
            let(:format) { 'blah' }

            before do
                @id = create_scan
            end

            it 'returns 400' do
                get url
                expect(response_code).to eq 400
            end
        end
    end

    describe 'PUT /scans/:id/pause' do
        let(:tpl_url) { '/scans/%s/pause' }

        before do
            @id = create_scan
        end

        it 'pauses the scan' do
            put url
            get "/scans/#{id}"

            expect(['pausing', 'paused']).to include response_data['status']
        end

        context 'when passed a non-existent id' do
            let(:id) { non_existent_id }

            it 'returns 404' do
                put url
                expect(response_code).to eq 404
            end
        end
    end

    describe 'PUT /scans/:id/resume' do
        let(:tpl_url) { '/scans/%s/resume' }

        before do
            @id = create_scan
        end

        it 'resumes the scan' do
            put "/scans/#{id}/pause"
            get "/scans/#{id}"

            expect(['pausing', 'paused']).to include response_data['status']

            put url
            get "/scans/#{id}"

            expect(response_data['status']).to eq 'scanning'
        end

        context 'when passed a non-existent id' do
            let(:id) { non_existent_id }

            it 'returns 404' do
                put url
                expect(response_code).to eq 404
            end
        end
    end

    describe 'DELETE /scans/:id' do
        let(:tpl_url) { '/scans/%s' }

        before do
            @id = create_scan
        end

        it 'aborts the scan' do
            get url
            expect(response_code).to eq 200

            delete url

            get "/scans/#{id}"
            expect(response_code).to eq 404
        end

        context 'when passed a non-existent id' do
            let(:id) { non_existent_id }

            it 'returns 404' do
                delete url
                expect(response_code).to eq 404
            end
        end
    end

end
