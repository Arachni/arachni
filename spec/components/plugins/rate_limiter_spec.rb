require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    def url
        @url ||= web_server_url_for( name_from_filename ) + '/'
    end

    before :each do
        options.plugins[component_name] = {
            'requests_per_second' => 2
        }

        framework.plugins.load name_from_filename
        framework.plugins.run
    end

    after :each do
        framework.clean_up
    end

    context 'when the server response times' do
        context 'are below threshold' do
            it 'sleeps one time' do
                http.max_concurrency = 1

                time_start = Time.now

                http.get(url)
                http.run

                run_time = Time.now - time_start

                expect(framework.plugins[component_name].times_slept).to eq(1)
                expect(framework.plugins[component_name].total_time_slept).to be <= 0.5
                expect(run_time).to be > 0.5
            end
        end

        context 'are above threshold' do
            it 'does not sleep' do
                http.max_concurrency = 1

                http.get(url + 'slow')
                http.run

                expect(framework.plugins[component_name].times_slept).to eq(0)
                expect(framework.plugins[component_name].total_time_slept).to eq(0.0)
            end
        end
    end
end
