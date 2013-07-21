require 'spec_helper'

describe Arachni::Element::Capabilities::Auditable::Taint do

    before :all do
        Arachni::Options.url = @url = web_server_url_for( :taint )
        @auditor = Auditor.new( nil, Arachni::Framework.new )

        @positive = Arachni::Element::Link.new( url: @url, inputs: { 'input' => '' } )
        @positive.auditor = @auditor
        @positive.auditor.page = Arachni::Page.from_url( @url )

        @negative = Arachni::Element::Link.new( url: @url, inputs: { 'inexistent_input' => '' } )
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
                auditable = Arachni::Element::Link.new(
                    url: 'http://stuff.com/',
                    inputs: { 'input' => '' }
                )
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

            context 'for matching with' do

                describe :regexp do
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

                    context 'without :match' do
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
                    it 'tries to find the provided substring' do
                        @positive.taint_analysis( @seed,
                            substring: @seed,
                            format: [ Arachni::Module::Auditor::Format::STRAIGHT ]
                         )
                        @auditor.http.run
                        issues.size.should == 1
                        issues.first.injected.should == @seed
                        issues.first.verification.should be_false
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

end
