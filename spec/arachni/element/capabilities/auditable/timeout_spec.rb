require_relative '../../../../spec_helper'

describe Arachni::Element::Capabilities::Auditable::Timeout do

    before :all do
        @url     = server_url_for( :timeout )
        @auditor = Auditor.new

        inputs = { 'sleep' => '' }

        @positive = Arachni::Element::Link.new( @url + '/true', inputs )
        @positive.auditor = @auditor

        @positive_high_res = Arachni::Element::Link.new(
            @url + '/high_response_time',
            inputs
        )
        @positive_high_res.auditor = @auditor

        @negative = Arachni::Element::Link.new( @url + '/false', inputs )
        @negative.auditor = @auditor

        @run = proc{ Arachni::Element::Capabilities::Auditable.timeout_audit_run }
    end

    before { Arachni::Framework.reset }

    describe '#responsive?' do
        context 'when the server is responsive' do
            it 'should return true' do
                Arachni::Element::Link.new( @url + '/true' ).responsive?.should be_true
            end
        end
        context 'when the server is not responsive' do
            it 'should return false' do
                Arachni::Element::Link.new( @url + '/sleep' ).responsive?( 1 ).should be_false
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

        describe :timeout_divider do
            context 'when set' do
                it 'should modify the final timeout value' do
                    @positive.timeout_analysis( '__TIME__',
                        @timeout_opts.merge(
                            timeout_divider: 1000,
                            timeout: 2000
                        )
                    )
                    @run.call

                    issues.should be_any
                    issues.first.injected.should == 4.to_s
                end
            end

            context 'when not set' do
                it 'should not modify the final timeout value' do
                    c = @positive.dup
                    c[:multi] = true
                    c.timeout_analysis( '__TIME__', @timeout_opts.merge( timeout: 2000 ))
                    @run.call

                    issues.should be_any
                    issues.first.injected.should == 4000.to_s
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
                it 'should not log issue' do
                    @negative.timeout_analysis( '__TIME__', @delay_opts )
                    @run.call
                    issues.should be_empty
                end
            end

            context 'and is vulnerable' do
                it 'should log issue' do
                    @positive_high_res.timeout_analysis( '__TIME__', @delay_opts )
                    @run.call
                    issues.should be_any
                end
            end
        end

    end

end
