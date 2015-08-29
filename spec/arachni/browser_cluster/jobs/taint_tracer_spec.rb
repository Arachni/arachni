require 'spec_helper'

describe Arachni::BrowserCluster::Jobs::TaintTrace do
    before(:each) { @cluster = Arachni::BrowserCluster.new }
    after(:each) do
        @cluster.shutdown
    end

    def test_execution_flow( job )
        pages = []

        @cluster.queue( job ) do |result|
            pages << result.page
        end
        @cluster.wait

        browser_cluster_job_taint_tracer_execution_flow_check_pages pages
    end

    def test_data_flow( job )
        pages = []

        @cluster.queue( job ) do |result|
            pages << result.page
        end
        @cluster.wait

        browser_cluster_job_taint_tracer_data_flow_check_pages pages
    end

    def test_data_flow_with_injector( job )
        pages = []

        @cluster.queue( job ) do |result|
            pages << result.page
        end
        @cluster.wait

        browser_cluster_job_taint_tracer_data_flow_with_injector_check_pages pages
    end

    context 'when tracing the data-flow' do
        let(:taint) { Arachni::Utilities.generate_token }
        let(:url) do
            Arachni::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) +
                "/data_trace/user-defined-global-functions?taint=#{taint}"
        end

        context 'and the resource is a' do
            context 'String' do
                it 'loads the URL and traces the taint' do
                    test_data_flow described_class.new(
                        resource: url,
                        taint:    taint
                    )
                end
            end

            context 'Arachni::HTTP::Response' do
                it 'loads it and traces the taint' do
                    test_data_flow described_class.new(
                        resource: Arachni::HTTP::Client.get( url, mode: :sync ),
                        taint:    taint
                    )
                end
            end

            context 'Arachni::Page' do
                it 'loads it and traces the taint' do
                    test_data_flow described_class.new(
                        resource: Arachni::Page.from_url( url ),
                        taint:    taint
                    )
                end
            end
        end

        context 'and requires a custom taint injector' do
            let(:injector) { "location.hash = #{taint.inspect}" }
            let(:url) do
                Arachni::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) +
                    'needs-injector'
            end

            context 'and the resource is a' do
                context 'String' do
                    it 'loads the URL and traces the taint' do
                        test_data_flow_with_injector described_class.new(
                            resource: url,
                            taint:    taint,
                            injector: injector
                        )
                    end
                end

                context 'Arachni::HTTP::Response' do
                    it 'loads it and traces the taint' do
                        test_data_flow_with_injector described_class.new(
                            resource: Arachni::HTTP::Client.get( url, mode: :sync ),
                            taint:    taint,
                            injector: injector
                        )
                    end
                end

                context 'Arachni::Page' do
                    it 'loads it and traces the taint' do
                        test_data_flow_with_injector described_class.new(
                            resource: Arachni::Page.from_url( url ),
                            taint:    taint,
                            injector: injector
                        )
                    end
                end
            end
        end
    end

    context 'when tracing the execution-flow' do
        let(:url) do
            Arachni::Utilities.normalize_url( web_server_url_for( :taint_tracer ) ) +
                "debug?input=_#{@cluster.javascript_token}TaintTracer.log_execution_flow_sink()"
        end

        context 'and the resource is a' do
            context 'String' do
                it 'loads the URL and traces the taint' do
                    test_execution_flow described_class.new( resource: url )
                end
            end

            context 'Arachni::HTTP::Response' do
                it 'loads it and traces the taint' do
                    test_execution_flow described_class.new(
                        resource: Arachni::HTTP::Client.get( url, mode: :sync )
                    )
                end
            end

            context 'Arachni::Page' do
                it 'loads it and traces the taint' do
                    test_execution_flow described_class.new(
                        resource: Arachni::Page.from_url( url )
                    )
                end
            end
        end
    end
end
