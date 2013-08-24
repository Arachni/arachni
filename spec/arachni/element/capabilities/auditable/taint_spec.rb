require 'spec_helper'

describe Arachni::Element::Capabilities::Auditable::Taint do

    before :all do
        Arachni::Options.url = @url = web_server_url_for( :taint )
        @auditor = Auditor.new( nil, Arachni::Framework.new )

        @positive = Arachni::Element::Link.new( @url, 'input' => '' )
        @positive.auditor = @auditor
        @positive.auditor.page = Arachni::Page.from_url( @url )

        @negative = Arachni::Element::Link.new( @url, 'inexistent_input' => '' )
        @negative.auditor = @auditor
        @negative.auditor.page = Arachni::Page.from_url( @url )
    end

    describe '.taint' do

        before do
            @seed = 'my_seed'
            Arachni::Framework.reset
         end

        context 'when the element action matches a skip rule' do
            it 'returns false' do
                auditable = Arachni::Element::Link.new( 'http://stuff.com/',
                                                        { 'input' => '' } )
                auditable.taint_analysis( @seed ).should be_false
            end
        end

        context 'when called with no opts' do
            it 'uses the defaults' do
                @positive.taint_analysis( @seed )
                @auditor.http.run
                issues.size.should == 1
            end
        end

        context 'when the payloads are per platform' do
            it 'assigns the platform of the payload to the issue' do
                payloads = {
                    windows: 'blah',
                    php:     @seed,
                }

                @positive.taint_analysis( payloads, substring: @seed )
                @auditor.http.run
                issues.size.should == 1
                issue = issues.first
                issue.platform.should == :php
                issue.platform_type.should == :languages
            end
        end

        context 'when called against non-vulnerable input' do
            it 'does not log an issue' do
                @negative.taint_analysis( @seed )
                @auditor.http.run
                issues.should be_empty
            end
        end

        context 'when called with option' do

            describe :regexp do
                context String do
                    it 'tries to match the provided pattern' do
                        @positive.taint_analysis( @seed,
                                                  regexp: @seed,
                                                  format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                        )
                        @auditor.http.run
                        issues.size.should == 1
                        issues.first.injected.should == @seed
                        issues.first.verification.should be_false
                    end
                end

                context Array do
                    it 'tries to match the provided patterns' do
                        @positive.taint_analysis( @seed,
                                                  regexp: [@seed],
                                                  format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                        )
                        @auditor.http.run
                        issues.size.should == 1
                        issues.first.injected.should == @seed
                        issues.first.verification.should be_false
                    end
                end

                context Hash do
                    it 'assigns the relevant platform to the issue' do
                        regexps = {
                            windows: /#{@seed} w.*/,
                            php:     /#{@seed} p.*/,
                        }

                        @positive.taint_analysis(
                            "#{@seed} windows",
                            regexp: regexps.dup,
                            format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                        )

                        @auditor.http.run

                        issues.size.should == 1
                        issues[0].platform.should == :windows
                        issues[0].regexp.should == regexps[:windows].to_s
                        issues[0].verification.should be_false
                    end

                    context 'when the payloads are per platform' do
                        it 'only tries to matches the regexps for that platform' do
                            issues = []
                            Arachni::Module::Manager.on_register_results_raw do |results|
                                issues += results
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

                            @positive.taint_analysis(
                                payloads.dup,
                                regexp: regexps.dup,
                                format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                            )

                            @auditor.http.run

                            issues.size.should == 3
                            payloads.keys.each do |platform|
                                issue = issues.find{ |i| i.platform == platform }

                                issue.injected.should == payloads[platform]
                                issue.platform.should == platform
                                issue.regexp.should == regexps[platform].to_s
                                issue.verification.should be_false
                            end
                        end

                        context 'when there is not a payload for the regexp platform' do
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

                                @positive.taint_analysis(
                                    payloads.dup,
                                    regexp: regexps.dup,
                                    format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                                )

                                @auditor.http.run

                                issues.size.should == 1
                                issue = issues.first

                                issue.platform.should == :asp
                                issue.regexp.should == regexps[:asp].to_s
                                issue.verification.should be_false
                            end
                        end
                    end
                end

                context 'with valid :match' do
                    it 'verifies the matched data with the provided string' do
                        @positive.taint_analysis( @seed,
                            regexp: /my_.+d/,
                            match: @seed,
                            format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                         )
                        @auditor.http.run
                        issues.size.should == 1
                        issues.first.injected.should == @seed
                        issues.first.verification.should be_false
                    end
                end

                context 'with invalid :match' do
                    it 'does not log an issue' do
                        @positive.taint_analysis( @seed,
                            regexp: @seed,
                            match: 'blah',
                            format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                         )
                        @auditor.http.run
                        issues.should be_empty
                    end
                end

                context 'when the page matches the regexp even before we audit it' do
                    it 'flags the issue as requiring manual verification' do
                        seed = 'Inject here'

                        @positive.taint_analysis( 'Inject here',
                            regexp: 'Inject he[er]',
                            format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                        )
                        @auditor.http.run
                        issues.size.should == 1

                        issue = issues.first

                        issue.injected.should == seed
                        issue.verification.should be_true
                        issue.remarks[:auditor].should be_any
                    end
                    it 'adds a remark' do
                        seed = 'Inject here'

                        @positive.taint_analysis( 'Inject here',
                                                  regexp: 'Inject he[er]',
                                                  format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                        )
                        @auditor.http.run
                        issues.size.should == 1

                        issue = issues.first

                        issue.injected.should == seed
                        issue.verification.should be_true
                        issue.remarks[:auditor].should be_any
                    end

                end
            end

            describe :substring do

                context String do
                    it 'tries to match the provided pattern' do
                        @positive.taint_analysis( @seed,
                                                  substring: @seed,
                                                  format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                        )
                        @auditor.http.run
                        issues.size.should == 1
                        issues.first.injected.should == @seed
                        issues.first.verification.should be_false
                    end
                end

                context Array do
                    it 'tries to match the provided patterns' do
                        @positive.taint_analysis( @seed,
                                                  substring: [@seed],
                                                  format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                        )
                        @auditor.http.run
                        issues.size.should == 1
                        issues.first.injected.should == @seed
                        issues.first.verification.should be_false
                    end
                end

                context Hash do
                    it 'assigns the relevant platform to the issue' do
                        substrings = {
                            windows: "#{@seed} w",
                            php:     "#{@seed} p",
                        }

                        @positive.taint_analysis(
                            "#{@seed} windows",
                            substring: substrings.dup,
                            format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                        )

                        @auditor.http.run

                        issues.size.should == 1
                        issues[0].platform.should == :windows
                        issues[0].regexp.should == substrings[:windows].to_s
                        issues[0].verification.should be_false
                    end

                    context 'when the payloads are per platform' do
                        it 'only tries to matches the regexps for that platform' do
                            issues = []
                            Arachni::Module::Manager.on_register_results_raw do |results|
                                issues += results
                            end

                            payloads = {
                                windows: "#{@seed} windows",
                                php:     "#{@seed} php",
                                asp:     "#{@seed} asp"
                            }

                            substrings = {
                                windows: "#{@seed} w",
                                php:     "#{@seed} p",

                                # Can match all but should only match
                                # against responses of the ASP payload.
                                asp:     @seed
                            }

                            @positive.taint_analysis(
                                payloads.dup,
                                substring: substrings.dup,
                                format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                            )

                            @auditor.http.run

                            issues.size.should == 3
                            payloads.keys.each do |platform|
                                issue = issues.find{ |i| i.platform == platform }

                                issue.injected.should == payloads[platform]
                                issue.platform.should == platform
                                issue.regexp.should == substrings[platform].to_s
                                issue.verification.should be_false
                            end
                        end
                    end
                end

                context 'when the page includes the substring even before we audit it' do
                    it 'flags the issue as requiring manual verification' do
                        seed = 'Inject here'

                        @positive.taint_analysis( 'Inject here',
                            regexp: 'Inject here',
                            format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                        )
                        @auditor.http.run
                        issues.size.should == 1

                        issue = issues.first

                        issue.injected.should == seed
                        issue.verification.should be_true
                        issue.remarks[:auditor].should be_any
                    end

                    context 'when there is not a payload for the substring platform' do
                        it 'matches against all payload responses and assigns the pattern platform to the issue' do
                            payloads = {
                                windows: "#{@seed} windows",
                                php:     "#{@seed} php",
                            }

                            substrings = {
                                # Can match all but should only match
                                # against responses of the ASP payload.
                                asp: @seed
                            }

                            @positive.taint_analysis(
                                payloads.dup,
                                substring: substrings.dup,
                                format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                            )

                            @auditor.http.run

                            issues.size.should == 1
                            issue = issues.first

                            issue.platform.should == :asp
                            issue.regexp.should == substrings[:asp].to_s
                            issue.verification.should be_false
                        end
                    end

                end
            end

            describe :ignore do
                it 'ignores matches whose response also matches the ignore patterns' do
                    @positive.taint_analysis( @seed,
                        substring: @seed,
                        format: [ Arachni::Module::Auditor::Format::STRAIGHT ],
                        ignore: @seed
                    )
                    @auditor.http.run
                    issues.should be_empty
                end
            end
        end

    end

end
