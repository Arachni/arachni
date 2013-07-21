require 'spec_helper'

describe Arachni::Element::Capabilities::Auditable::Timeout do

    before :all do
        Arachni::Options.url = @url = web_server_url_for( :timeout )
        @auditor = Auditor.new( nil, Arachni::Framework.new )

        inputs = { 'sleep' => '' }

        @positive = Arachni::Element::Link.new( url: @url + '/true', inputs: inputs )
        @positive.auditor = @auditor
        @positive.disable_deduplication

        @positive_high_res = Arachni::Element::Link.new(
            url:    @url + '/high_response_time',
            inputs: inputs
        )
        @positive_high_res.auditor = @auditor

        @negative = Arachni::Element::Link.new( url: @url + '/false', inputs: inputs )
        @negative.auditor = @auditor
        @negative.disable_deduplication

        @run = proc do
            Arachni::HTTP::Client.run
            Arachni::Element::Capabilities::Auditable.timeout_audit_run
        end
    end

    before { Arachni::Framework.reset }

    describe '#responsive?' do
        context 'when the server is responsive' do
            it 'returns true' do
                Arachni::Element::Link.new( url: @url + '/true' ).responsive?.should be_true
            end
        end
        context 'when the server is not responsive' do
            it 'returns false' do
                Arachni::Element::Link.new( url: @url + '/sleep' ).responsive?( 1 ).should be_false
            end
        end
    end

    describe '#timeout_analysis' do
        before do
            @timeout_opts = {
                format: [ Arachni::Module::Auditor::Format::STRAIGHT ],
                elements: [ Arachni::Element::LINK ]
            }
            issues.clear
        end

        context 'when the element action matches a skip rule' do
            it 'returns false' do
                auditable = Arachni::Element::Link.new(
                    url:    'http://stuff.com/',
                    inputs: { 'input' => '' }
                )
                auditable.timeout_analysis( '__TIME__', @timeout_opts.merge( timeout: 2000 ) ).should be_false
            end
        end

        context 'when the payloads are per platform' do
            it 'assigns the platform of the payload to the issue' do
                payloads = {
                    windows: '__TIME__',
                    php:     'seed',
                }

                @positive.timeout_analysis( payloads,
                    @timeout_opts.merge(
                        timeout_divider: 1000,
                        timeout: 2000
                    )
                )
                @run.call

                issue = issues.first
                issue.platform.should == :windows
                issue.platform_type.should == :os
            end
        end

        describe :timeout_divider do
            context 'when set' do
                it 'modifies the final timeout value' do
                    @positive.timeout_analysis( '__TIME__',
                        @timeout_opts.merge(
                            timeout_divider: 1000,
                            timeout: 2000
                        )
                    )
                    @run.call

                    issues.should be_any
                    issues.first.injected.should == '8'
                end
            end

            context 'when not set' do
                it 'does not modify the final timeout value' do
                    c = @positive.dup
                    c[:multi] = true
                    c.timeout_analysis( '__TIME__', @timeout_opts.merge( timeout: 2000 ))
                    @run.call

                    issues.should be_any
                    issues.first.injected.should == 8000.to_s
                end
            end
        end

        context 'when a page has a high response time' do
            before do
                @delay_opts = {
                    timeout_divider: 1000,
                    timeout: 2000
                }.merge( @timeout_opts )
            end

            context 'but isn\'t vulnerable' do
                it 'does not log an issue' do
                    @negative.timeout_analysis( '__TIME__', @delay_opts )
                    @run.call
                    issues.should be_empty
                end
            end

            context 'and is vulnerable' do
                it 'logs an issue' do
                    @positive_high_res.timeout_analysis( '__TIME__', @delay_opts )
                    @run.call
                    issues.should be_any
                end
            end
        end

    end

end
