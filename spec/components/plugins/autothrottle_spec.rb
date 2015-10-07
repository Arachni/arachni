require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    def url
        @url ||= web_server_url_for( name_from_filename ) + '/'
    end

    before :each do
        framework.plugins.load name_from_filename
        framework.plugins.run
    end

    after :each do
        framework.clean_up
    end

    context 'when the server response times are' do
        context 'bellow threshold' do
            it 'does not touch the max concurrency' do
                pre = http.max_concurrency

                http.max_concurrency.times { http.get( url ) }
                http.run

                expect(http.max_concurrency).to eq(pre)
            end
        end
        context 'above threshold' do
            it 'reduces the max concurrency' do
                pre = http.max_concurrency

                http.max_concurrency.times { http.get( url + 'slow' ) }
                http.run

                expect(http.max_concurrency).to be < pre
            end

            context 'and then fall bellow threshold' do
                it 'increases the max concurrency (without exceeding http_request_concurrency)' do
                    http.max_concurrency.times { http.get( url + 'slow' ) }
                    http.run
                    expect(http.max_concurrency).to be < options.http.request_concurrency

                    pre = http.max_concurrency

                    (10 * http.max_concurrency).times { http.get( url ) }
                    http.run

                    expect(http.max_concurrency).to be > pre
                    expect(http.max_concurrency).to be <= options.http.request_concurrency
                end
            end
        end
    end
end
