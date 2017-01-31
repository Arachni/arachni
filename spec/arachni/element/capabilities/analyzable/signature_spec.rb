require 'spec_helper'

describe Arachni::Element::Capabilities::Analyzable::Signature do

    before :all do
        Arachni::Options.url = @url = web_server_url_for( :signature )
        Arachni::Options.audit.elements :links

        @auditor = Auditor.new( Arachni::Page.from_url( @url ), Arachni::Framework.new )

        @positive = Arachni::Element::Link.new( url: @url, inputs: { 'input' => '' } )
        @positive.auditor = @auditor
        @positive.auditor.page = Arachni::Page.from_url( @url )

        @negative = Arachni::Element::Link.new( url: @url, inputs: { 'inexistent_input' => '' } )
        @negative.auditor = @auditor
        @negative.auditor.page = Arachni::Page.from_url( @url )
    end

    describe '#signature_analysis' do
        before do
            @seed = 'my_seed'
            Arachni::Framework.reset
        end

        context 'when the element action matches a skip rule' do
            it 'returns false' do
                auditable = Arachni::Element::Link.new(
                    url: 'http://stuff.com/',
                    inputs: { 'input' => '' }
                )
                expect(auditable.signature_analysis( @seed )).to be_falsey
            end
        end

        context 'when called with no opts' do
            it 'uses the defaults' do
                @positive.signature_analysis( @seed )
                @auditor.http.run
                expect(issues.size).to eq(1)
            end
        end

        context 'when the payloads are per platform' do
            it 'assigns the platform of the payload to the issue' do
                payloads = {
                    windows: 'blah',
                    php:     @seed,
                }

                @positive.signature_analysis( payloads, signature: @seed )
                @auditor.http.run
                expect(issues.size).to eq(1)
                issue = issues.first
                expect(issue.platform_name).to eq(:php)
                expect(issue.platform_type).to eq(:languages)
            end
        end

        context 'when called against non-vulnerable input' do
            it 'does not log an issue' do
                @negative.signature_analysis( @seed )
                @auditor.http.run
                expect(issues).to be_empty
            end
        end

        context 'when called with option' do
            describe ':signatures' do
                context 'String' do
                    it 'tries to match the provided pattern' do
                        @positive.signature_analysis(
                            @seed,
                            signatures: @seed,
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ]
                        )
                        @auditor.http.run
                        expect(issues.size).to eq(1)
                        expect(issues.first.vector.seed).to eq(@seed)
                    end
                end

                context 'Regexp' do
                    it 'tries to match the provided pattern' do
                        @positive.signature_analysis(
                            @seed,
                            signatures: Regexp.new( @seed ),
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ]
                        )
                        @auditor.http.run
                        expect(issues.size).to eq(1)
                        expect(issues.first.vector.seed).to eq(@seed)
                        expect(issues.first).to be_trusted
                    end

                    context 'multi-line' do
                        it 'raises error' do
                            expect do
                                @positive.signature_analysis(
                                    @seed,
                                    signatures: /ff/m
                                )
                            end.to raise_error ArgumentError
                        end
                    end
                end

                context 'Array' do
                    it 'tries to match the provided patterns' do
                        @positive.signature_analysis(
                            @seed,
                            signatures: [@seed],
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ]
                        )
                        @auditor.http.run
                        expect(issues.size).to eq(1)
                        expect(issues.first.vector.seed).to eq(@seed)
                    end

                    context 'with multi-line Regexp' do
                        it 'raises error' do
                            expect do
                                @positive.signature_analysis(
                                    @seed,
                                    signatures: [/ff/m]
                                )
                            end.to raise_error ArgumentError
                        end
                    end
                end

                context 'Hash' do
                    it 'assigns the relevant platform to the issue' do
                        regexps = {
                            windows: /#{@seed} w.*/,
                            php:     /#{@seed} p.*/,
                        }

                        @positive.signature_analysis(
                            "#{@seed} windows",
                            signatures: regexps.dup,
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ]
                        )

                        @auditor.http.run

                        expect(issues.size).to eq(1)
                        expect(issues[0].platform_name).to eq(:windows)
                        expect(issues[0].signature).to eq(regexps[:windows].source)
                    end

                    context 'with multi-line Regexp' do
                        it 'raises error' do
                            expect do
                                @positive.signature_analysis(
                                    @seed,
                                    signatures: {
                                        windows: /ff/m
                                    }
                                )
                            end.to raise_error ArgumentError

                            expect do
                                @positive.signature_analysis(
                                    @seed,
                                    signatures: {
                                        windows: [/ff/m]
                                    }
                                )
                            end.to raise_error ArgumentError
                        end
                    end

                    context 'when the payloads are per platform' do
                        it 'only tries to matches the regexps for that platform' do
                            issues = []
                            Arachni::Data.issues.on_new_pre_deduplication do |issue|
                                issues << issue
                            end

                            payloads = {
                                windows: "#{@seed} windows",
                                php:     "#{@seed} php",
                                asp:     "#{@seed} asp"
                            }

                            regexps = {
                                windows: /#{@seed} w.*/,
                                php:     /#{@seed} p.*/,

                                # Can match all but should only match
                                # against responses of the ASP payload.
                                asp:     /#{@seed}/
                            }

                            @positive.signature_analysis(
                                payloads.dup,
                                signatures: regexps.dup,
                                format: [ Arachni::Check::Auditor::Format::STRAIGHT ]
                            )

                            @auditor.http.run

                            expect(issues.size).to eq(3)
                            payloads.keys.each do |platform|
                                issue = issues.find{ |i| i.platform_name == platform }

                                expect(issue.vector.seed).to eq(payloads[platform])
                                expect(issue.platform_name).to eq(platform)
                                expect(issue.signature).to eq(regexps[platform].source)
                            end
                        end

                        context 'when there is not a payload for the platform' do
                            it 'matches against all payload responses and assigns the pattern platform to the issue' do
                                payloads = {
                                    windows: "#{@seed} windows",
                                    php:     "#{@seed} php",
                                }

                                regexps = {
                                    # Can match all but should only match
                                    # against responses of the ASP payload.
                                    asp: /#{@seed}/
                                }

                                @positive.signature_analysis(
                                    payloads.dup,
                                    signatures: regexps.dup,
                                    format: [ Arachni::Check::Auditor::Format::STRAIGHT ]
                                )

                                @auditor.http.run

                                expect(issues.size).to eq(1)
                                issue = issues.first

                                expect(issue.platform_name).to eq(:asp)
                                expect(issue.signature).to eq(regexps[:asp].source)
                            end
                        end
                    end
                end

                context 'when the page matches the regexp even before we audit it' do
                    it 'does not log an issue' do
                        @positive.signature_analysis( 'Inject here',
                            signatures: 'Inject he[er]',
                            format: [ Arachni::Check::Auditor::Format::STRAIGHT ]
                        )
                        @auditor.http.run
                        expect(issues).to be_empty
                    end
                end
            end

            describe ':ignore' do
                it 'ignores matches whose response also matches the ignore patterns' do
                    @positive.signature_analysis( @seed,
                        signatures: @seed,
                        format: [ Arachni::Check::Auditor::Format::STRAIGHT ],
                        ignore: @seed
                    )
                    @auditor.http.run
                    expect(issues).to be_empty
                end
            end
        end
    end

end
