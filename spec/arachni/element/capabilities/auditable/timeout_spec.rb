require 'spec_helper'

describe Arachni::Element::Capabilities::Auditable::Timeout do

    before :all do
        Arachni::Options.url = @url = web_server_url_for( :timeout )
        @auditor = Auditor.new( nil, Arachni::Framework.new )

        @inputs = { 'sleep' => '' }

        @positive = Arachni::Element::Link.new( url: @url + '/true', inputs: @inputs )
        @positive.auditor = @auditor

        @positive_high_res = Arachni::Element::Link.new(
            url: @url + '/high_response_time',
            inputs: @inputs
        )
        @positive_high_res.auditor = @auditor

        @negative = Arachni::Element::Link.new( url: @url + '/false', inputs: @inputs )
        @negative.auditor = @auditor

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
                format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                elements: [ Arachni::Element::LINK ]
            }
            issues.clear
        end

        context 'when the element action matches a skip rule' do
            it 'returns false' do
                auditable = Arachni::Element::Link.new(
                    url: 'http://stuff.com/',
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
                                                timeout:         2000
                                            )
                )
                @run.call

                issue = issues.first
                issue.platform.should == :windows
                issue.platform_type.should == :os
            end
        end

        describe :timeout do
            it 'sets the delay' do
                c = Arachni::Element::Link.new(
                    url: @url + '/true',
                    inputs: @inputs.merge( mili: true )
                )
                c.auditor = @auditor
                c.audit_options[:skip_like] = proc { |m| m.altered == 'multi' }

                c.timeout_analysis( '__TIME__', @timeout_opts.merge( timeout: 2000 ) )
                @run.call

                issues.should be_any
                issues.first.injected.should == '8000'
            end
        end

        describe :timeout_divider do
            it 'modifies the final timeout value' do
                @positive.timeout_analysis( '__TIME__',
                                            @timeout_opts.merge(
                                                timeout_divider: 1000,
                                                timeout:         2000
                                            )
                )
                @run.call

                issues.should be_any
                issues.first.injected.should == '8'
            end
        end

        describe :add do
            it 'adds the given integer to the expected webapp delay' do
                c = Arachni::Element::Link.new( url: @url + '/add', inputs: @inputs )
                c.auditor = @auditor

                c.timeout_analysis(
                    '__TIME__',
                    @timeout_opts.merge( timeout: 3000, timeout_divider: 1000, add: -1000 )
                )
                @run.call

                issues.should be_any
                issues.first.response.should == '11'
            end
        end

        context 'when a page has a high response time' do
            before do
                @delay_opts = {
                    timeout_divider: 1000,
                    timeout:         4000
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
