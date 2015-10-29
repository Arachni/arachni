require 'spec_helper'
require "#{Arachni::Options.paths.lib}/rest/server"

describe Arachni::Rest::Server do
    include RequestHelpers

    let(:scan_url) { 'http://testfire.net' }
    let(:url) { tpl_url % id }
    let(:id) { @id }
    let(:non_existent_id) { 'stuff' }

    def create_scan
        post '/scans',
             url: scan_url,
             browser_cluster: {
                 pool_size: 0
             }
        response_data['id']
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
                expect(response_data['ids']).to include id
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
                ids = response_data['ids']

                post url, stuff: scan_url

                get '/scans'
                expect(response_data['ids'] - ids).to be_empty
            end
        end
    end

    describe 'GET /scans/:id' do
        let(:tpl_url) { '/scans/%s' }

        before do
            @id = create_scan
        end

        it 'gets progress info' do
            get url

            %w(issues sitemap errors status busy statistics messages).each do |key|
                expect(response_data).to include key
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

    describe 'GET /scans/:id/report.json' do
        let(:tpl_url) { '/scans/%s/report.json' }

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

        context 'when passed a non-existent id' do
            let(:id) { non_existent_id }

            it 'returns 404' do
                get url
                expect(response_code).to eq 404
            end
        end
    end

    describe 'GET /scans/:id/report.xml' do
        let(:tpl_url) { '/scans/%s/report.xml' }

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

        context 'when passed a non-existent id' do
            let(:id) { non_existent_id }

            it 'returns 404' do
                get url
                expect(response_code).to eq 404
            end
        end
    end

    describe 'GET /scans/:id/report.yaml' do
        let(:tpl_url) { '/scans/%s/report.yaml' }

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

        context 'when passed a non-existent id' do
            let(:id) { non_existent_id }

            it 'returns 404' do
                get url
                expect(response_code).to eq 404
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

            expect(response_data['status']).to eq 'pausing'
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

            expect(response_data['status']).to eq 'pausing'

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
