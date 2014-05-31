require 'spec_helper'

describe Arachni::Element::Capabilities::Analyzable::Timeout do

    def run
        Arachni::HTTP::Client.run
        Arachni::Element::Capabilities::Analyzable.timeout_audit_run
    end

    before :all do
        Arachni::Options.url = @url = web_server_url_for( :timeout )
        @framework = Arachni::Framework.new
    end

    after :each do
        @framework.reset
    end

    let(:framework) { @framework }
    let(:page) { Arachni::Page.from_url( @url ) }
    let(:inputs) { { 'sleep' => '' } }
    let(:auditor) { Auditor.new( page, framework ) }
    let(:subject) do
        e = Arachni::Element::Link.new( url: @url + '/true', inputs: inputs )
        e.auditor = auditor
        e
    end
    let(:options) do
        {
            format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
            elements: [ Arachni::Element::Link ]
        }
    end

    describe '#responsive?' do
        context 'when the server is responsive' do
            it 'returns true' do
                subject.responsive?.should be_true
            end
        end
        context 'when the server is not responsive' do
            it 'returns false' do
                Arachni::Element::Link.new( url: @url + '/sleep' ).
                    responsive?( 1 ).should be_false
            end
        end
    end

    describe '#has_candidates?' do
        context 'when there are candidates' do
            it 'returns true' do
                described_class.add_phase_2_candidate subject
                described_class.has_candidates?.should be_true
            end
        end

        context 'when there are no candidates' do
            it 'returns false' do
                described_class.has_candidates?.should be_false
            end
        end
    end

    describe '#timing_attack_probe' do
        let(:options) do
            super().merge!(
                timeout_divider: 1000,
                timeout:         2000
            )
        end

        context 'when element submission results in a response with a response time' do
            context 'higher than the given delay' do
                it 'passes it to the block' do
                    candidate = nil
                    subject.timing_attack_probe( '__TIME__', options ) do |element|
                        candidate ||= element
                    end
                    run

                    candidate.should be_true
                end
            end

            context 'lower than the given delay' do
                subject do
                    Arachni::Element::Link.new(
                        url:    @url,
                        inputs: inputs
                    )
                end

                it 'ignores it' do
                    candidate = nil
                    subject.timing_attack_probe( '__TIME__', options ) do |element|
                        candidate ||= element
                    end
                    run

                    candidate.should be_nil
                end
            end
        end
    end

    describe '#timing_attack_verify' do
        let(:options) do
            super().merge!(
                timeout_divider: 1000,
                timeout:         2000
            )
        end

        context 'when the delay could not be verified' do
            subject do
                e = Arachni::Element::Link.new(
                    url:    "#{@url}/verification_fail",
                    inputs: inputs
                )
                e.auditor = auditor
                e
            end

            it 'does not call the given block' do
                candidate = nil
                subject.timing_attack_probe( '__TIME__', options ) do |element|
                    candidate ||= element
                end
                run

                candidate.should be_true

                verified = nil
                candidate.timing_attack_verify( 1000 ) do
                    verified = true
                end

                verified.should be_nil
            end
        end

        context 'when the delay could be verified' do
            it 'passes the element and response to the given block' do
                candidate = nil
                subject.timing_attack_probe( '__TIME__', options ) do |element|
                    candidate ||= element
                end
                run

                response = nil
                mutation = nil
                candidate.timing_attack_verify( 4000 ) do |m, r|
                    response = r
                    mutation = m
                end

                mutation.should be_kind_of candidate.class
                response.should be_kind_of Arachni::HTTP::Response
            end
        end

        context 'when the request times out by default' do
            subject do
                e = Arachni::Element::Link.new(
                    url:    @url + '/sleep',
                    inputs: inputs
                )
                e.auditor = auditor
                e
            end

            it 'does not call the given block' do
                candidate = nil
                subject.timing_attack_probe( '__TIME__', options ) do |element|
                    candidate ||= element
                end
                run

                candidate.should be_true

                verified = nil
                candidate.timing_attack_verify( 1000 ) do
                    verified = true
                end

                verified.should be_nil
            end
        end
    end

    describe '#timeout_analysis' do
        context 'when the element action matches a skip rule' do
            subject do
                Arachni::Element::Link.new(
                    url:    'http://stuff.com/',
                    inputs: { 'input' => '' }
                )
            end

            it 'returns false' do
                subject.timeout_analysis(
                    '__TIME__',
                    options.merge( timeout: 2000 )
                ).should be_false
            end
        end

        context 'when the payloads are per platform' do
            it 'assigns the platform of the payload to the issue' do
                payloads = {
                    windows: '__TIME__',
                    php:     'seed',
                }

                subject.timeout_analysis(
                    payloads,
                    options.merge(
                        timeout_divider: 1000,
                        timeout:         2000
                    )
                )
                run

                issue = issues.first
                issue.platform_name.should == :windows
                issue.platform_type.should == :os
            end
        end

        describe :timeout do
            it 'sets the delay' do
                c = Arachni::Element::Link.new(
                    url:    @url + '/true',
                    inputs: inputs.merge( mili: true )
                )
                c.auditor = auditor
                c.immutables << 'multi'

                c.timeout_analysis( '__TIME__', options.merge( timeout: 2000 ) )
                run

                issues.should be_any
                issues.flatten.first.vector.seed.should == '8000'
            end
        end

        describe :timeout_divider do
            it 'modifies the final timeout value' do
                subject.timeout_analysis( '__TIME__',
                                            options.merge(
                                                timeout_divider: 1000,
                                                timeout:         2000
                                            )
                )
                run

                issues.should be_any
                issues.flatten.first.vector.seed.should == '8'
            end
        end

        describe :add do
            it 'adds the given integer to the expected webapp delay' do
                c = Arachni::Element::Link.new( url: @url + '/add', inputs: inputs )
                c.auditor = auditor

                c.timeout_analysis(
                    '__TIME__',
                    options.merge(
                        timeout:         3000,
                        timeout_divider: 1000,
                        add:             -1000
                    )
                )
                run

                issues.should be_any
                issues.flatten.first.response.time.to_i.should == 11
            end
        end
    end

end
