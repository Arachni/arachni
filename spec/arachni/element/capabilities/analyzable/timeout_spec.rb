require 'spec_helper'

describe Arachni::Element::Capabilities::Analyzable::Timeout do

    def run
        Arachni::HTTP::Client.run
        Arachni::Element::Capabilities::Analyzable.timeout_audit_run
    end

    before :all do
        Arachni::Options.url = @url = web_server_url_for( :timeout )
        Arachni::Options.audit.elements :links

        @framework = Arachni::Framework.new
    end

    before :each do
        # Timing attacks should not download any content.
        Arachni::HTTP::Client.on_complete do |response|
            next if response.url.include? 'ignore'

            expect(response.body).to be_empty
        end
    end

    after :each do
        @framework.reset
    end

    let(:framework) { @framework }
    let(:page) { Arachni::Page.from_url( "#{@url}?ignore" ) }
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

    describe '#dup' do
        context 'when #timing_attack_remark_data is' do
            context 'not nil' do
                it 'duplicates it' do
                    h = { stuff: [1] }

                    subject.timing_attack_remark_data = h

                    dupped = subject.dup
                    expect(dupped).to eq(dupped)
                    expect(dupped.timing_attack_remark_data).to eq(h)
                    expect(dupped.timing_attack_remark_data.object_id).not_to eq(h.object_id)
                end
            end
        end
    end

    describe '#to_rpc_data' do
        it "does not include 'timing_attack_remark_data'" do
            expect(subject.to_rpc_data).not_to include 'timing_attack_remark_data'
        end
    end

    describe '#timeout_id' do
        let(:action) { "#{@url}/action" }

        it 'takes into account the #auditor class' do
            subject.auditor = 1
            id = subject.timeout_id

            subject.auditor = '2'
            expect(subject.timeout_id).not_to eq(id)

            subject.auditor = 1
            id = subject.timeout_id

            subject.auditor = 2
            expect(subject.timeout_id).to eq(id)
        end

        it 'takes into account #action' do
            e = subject.dup
            allow(e).to receive(:action) { action }

            c = subject.dup
            allow(c).to receive(:action) { "#{action}2" }

            expect(e.timeout_id).not_to eq(c.timeout_id)
        end

        it 'takes into account #type' do
            e = subject.dup
            allow(e).to receive(:type) { :blah }

            c = subject.dup
            allow(c).to receive(:type) { :blooh }

            expect(e.timeout_id).not_to eq(c.timeout_id)
        end

        it 'takes into account #inputs names' do
            e = subject.dup
            allow(e).to receive(:inputs) { {input1: 'stuff' } }

            c = subject.dup
            allow(c).to receive(:inputs) { {input1: 'stuff2' } }
            expect(e.timeout_id).to eq(c.timeout_id)

            e = subject.dup
            allow(e).to receive(:inputs) { {input1: 'stuff' } }

            c = subject.dup
            allow(c).to receive(:inputs) { {input2: 'stuff' } }

            expect(e.timeout_id).not_to eq(c.timeout_id)
        end

        it 'takes into account the #affected_input_value' do
            e = subject.dup
            allow(e).to receive(:affected_input_value) { :blah }

            c = subject.dup
            allow(c).to receive(:affected_input_value) { :blooh }

            expect(e.timeout_id).not_to eq(c.timeout_id)
        end

        it 'takes into account the #affected_input_name' do
            e = subject.dup
            allow(e).to receive(:affected_input_name) { :blah }

            c = subject.dup
            allow(c).to receive(:affected_input_name) { :blooh }

            expect(e.timeout_id).not_to eq(c.timeout_id)
        end
    end

    describe '#ensure_responsiveness' do
        context 'when the server is responsive' do
            it 'returns true' do
                expect(subject.ensure_responsiveness).to be_truthy
            end
        end
        context 'when the server is not responsive' do
            it 'returns false' do
                expect(Arachni::Element::Link.new( url: @url + '/sleep' ).
                    ensure_responsiveness( 1 )).to be_falsey
            end
        end
    end

    describe '#has_candidates?' do
        context 'when there are candidates' do
            it 'returns true' do
                described_class.add_phase_2_candidate subject
                expect(described_class.has_candidates?).to be_truthy
            end
        end

        context 'when there are no candidates' do
            it 'returns false' do
                expect(described_class.has_candidates?).to be_falsey
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

        it 'does not download response bodies' do
            response = nil
            subject.timing_attack_probe( '__TIME__', options ) do |_, r|
                response ||= r
            end
            run

            expect(response.body).to be_empty
        end

        context 'when element submission results in a response with a response time' do
            context 'higher than the given delay' do
                it 'passes it to the block' do
                    candidate = nil
                    subject.timing_attack_probe( '__TIME__', options ) do |element|
                        candidate ||= element
                    end
                    run

                    expect(candidate).to be_truthy
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

                    expect(candidate).to be_nil
                end
            end
        end

        context 'when no block has been given' do
            it 'raises ArgumentError' do
                expect { subject.timing_attack_probe( '1' ) }.to raise_error ArgumentError
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

                expect(candidate).to be_truthy

                verified = nil
                candidate.timing_attack_verify( 1000 ) do
                    verified = true
                end

                expect(verified).to be_nil
            end
        end

        context 'when the delay could be verified' do
            it 'passes the response to the given block' do
                candidate = nil
                subject.timing_attack_probe( '__TIME__', options ) do |element|
                    candidate ||= element
                end
                run

                response = nil
                candidate.timing_attack_verify( 4000 ) do |r|
                    response = r
                end

                expect(response).to be_kind_of Arachni::HTTP::Response
            end
        end

        context 'when the request times out' do
            context 'by default' do
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

                    expect(candidate).to be_truthy

                    verified = nil
                    candidate.timing_attack_verify( 1000 ) do
                        verified = true
                    end

                    expect(verified).to be_nil
                end
            end

            context 'due to filtering' do
                subject do
                    e = Arachni::Element::Link.new(
                        url:    @url + '/waf',
                        inputs: inputs
                    )
                    e.auditor = auditor
                    e
                end

                it 'does not call the given block' do
                    candidate = nil
                    subject.timing_attack_probe( 'payload-__TIME__', options ) do |element|
                        candidate ||= element
                    end
                    run

                    expect(candidate).to be_truthy

                    verified = nil
                    candidate.timing_attack_verify( 1000 ) do
                        verified = true
                    end

                    expect(verified).to be_nil
                end
            end
        end

        context 'when no block has been given' do
            it 'raises ArgumentError' do
                expect { subject.timing_attack_probe( '1' ) }.to raise_error ArgumentError
            end
        end
    end

    describe '#timeout_analysis' do
        it 'assigns assigns :timing_attack remarks' do
            subject.timeout_analysis(
                '__TIME__',
                options.merge(
                    timeout_divider: 1000,
                    timeout:         2000
                )
            )
            run

            expect(issues.first.remarks[:timing_attack].size).to eq(3)
        end

        context 'when the element action matches a skip rule' do
            subject do
                Arachni::Element::Link.new(
                    url:    'http://stuff.com/',
                    inputs: { 'input' => '' }
                )
            end

            it 'returns false' do
                expect(subject.timeout_analysis(
                    '__TIME__',
                    options.merge( timeout: 2000 )
                )).to be_falsey
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
                expect(issue.platform_name).to eq(:windows)
                expect(issue.platform_type).to eq(:os)
            end
        end

        describe ':timeout' do
            it 'sets the delay' do
                c = Arachni::Element::Link.new(
                    url:    @url + '/true',
                    inputs: inputs.merge( mili: true )
                )
                c.auditor = auditor
                c.immutables << 'multi'

                c.timeout_analysis( '__TIME__', options.merge( timeout: 2000 ) )
                run

                expect(issues).to be_any
                expect(issues.flatten.first.vector.seed).to eq('8000')
            end
        end

        describe ':timeout_divider' do
            it 'modifies the final timeout value' do
                subject.timeout_analysis( '__TIME__',
                                            options.merge(
                                                timeout_divider: 1000,
                                                timeout:         2000
                                            )
                )
                run

                expect(issues).to be_any
                expect(issues.flatten.first.vector.seed).to eq('8')
            end
        end

        describe ':add' do
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

                expect(issues).to be_any
                expect(issues.flatten.first.request.timeout).to eq(11_000)
            end
        end
    end

end
