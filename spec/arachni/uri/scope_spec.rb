require 'spec_helper'

describe Arachni::URI::Scope do

    before :each do
        Arachni::Options.reset
    end

    let(:scope){ Arachni::Options.scope }

    describe '#too_deep?' do
        subject { Arachni::URI.parse( '/very/very/very/very/deep' ).scope }

        context 'when the directory depth of the URL is' do
            context "less than #{Arachni::OptionGroups::Scope}#directory_depth_limit" do
                it 'returns false' do
                    scope.directory_depth_limit = 100
                    subject.too_deep?.should be_false
                end
            end

            context "less than #{Arachni::OptionGroups::Scope}#directory_depth_limit" do
                it 'returns true' do
                    scope.directory_depth_limit = 2
                    subject.too_deep?.should be_true
                end
            end
        end

        context "when #{Arachni::OptionGroups::Scope}#directory_depth_limit has not been configured" do
            it 'returns false' do
                subject.too_deep?.should be_false
            end
        end
    end

    describe '#redundant?' do
        subject { Arachni::URI.parse( 'http://stuff.com/match_this' ).scope }

        context 'when the update_counters option is' do
            context 'true' do
                it 'decrements the counters' do
                    scope.redundant_path_patterns = { /match_this/ => 10 }

                    10.times do
                        subject.redundant?( true ).should be_false
                    end

                    scope.redundant_path_patterns[/match_this/].should == 0
                end
            end

            context 'false' do
                it 'does not decrement the counters' do
                    scope.redundant_path_patterns = { /match_this/ => 10 }

                    10.times do
                        subject.redundant?.should be_false
                    end

                    scope.redundant_path_patterns[/match_this/].should == 10
                end
            end

            context 'default' do
                it 'does not decrement the counters' do
                    scope.redundant_path_patterns = { /match_this/ => 10 }

                    10.times do
                        subject.redundant?.should be_false
                    end

                    scope.redundant_path_patterns[/match_this/].should == 10
                end
            end
        end

        context "when a URL's counter reaches 0" do
            it 'returns true' do
                scope.redundant_path_patterns = { /match_this/ => 10 }

                10.times do
                    subject.redundant?( true ).should be_false
                end

                subject.redundant?( true ).should be_true
            end
        end
        context "when a URL's counter has not reached 0" do
            it 'returns false' do
                scope.redundant_path_patterns = { /match_this/ => 11 }

                10.times do
                    subject.redundant?( true ).should be_false
                end

                subject.redundant?( true ).should be_false
            end
        end

        context 'when #auto_redundant returns true' do
            it 'returns true' do
                subject.stub(:auto_redundant?) { true }
                subject.should be_redundant
            end
        end
    end

    describe '#auto_redundant?' do
        subject { Arachni::URI( 'http://test.com/?test=2&test2=2').scope }

        context 'when the update_counters option is' do
            context 'true' do
                it 'decrements the counters' do
                    scope.auto_redundant_paths = 10

                    subject.auto_redundant?( true ).should be_false
                    9.times do
                        subject.auto_redundant?( true ).should be_false
                    end

                    subject.auto_redundant?.should be_true
                end
            end

            context 'false' do
                it 'does not decrement the counters' do
                    scope.auto_redundant_paths = 10

                    subject.auto_redundant?( false ).should be_false
                    9.times do
                        subject.auto_redundant?( false ).should be_false
                    end

                    subject.auto_redundant?( false ).should_not be_true
                end
            end

            context 'default' do
                it 'does not decrement the counters' do
                    scope.auto_redundant_paths = 10

                    subject.auto_redundant?.should be_false
                    9.times do
                        subject.auto_redundant?.should be_false
                    end

                    subject.auto_redundant?.should_not be_true
                end
            end
        end

        context 'when #auto_redundant_paths limit has been reached' do
            it 'returns true' do
                scope.auto_redundant_paths = 10

                subject.auto_redundant?( true ).should be_false
                9.times do
                    subject.auto_redundant?( true ).should be_false
                end

                subject.auto_redundant?( true ).should be_true
            end
        end

        describe 'by default' do
            it 'returns false' do
                subject.auto_redundant?.should be_false
            end
        end

        describe 'when the URL has no parameters' do
            subject { Arachni::URI( 'http://test.com/').scope }

            it 'returns false' do
                scope.auto_redundant_paths = 1
                3.times do
                    subject.auto_redundant?.should be_false
                end
            end
        end
    end

    describe '#exclude?' do
        subject { Arachni::URI.parse( 'http://test.com/exclude/' ).scope }

        context 'when self matches the provided exclude rules' do
            it 'returns true' do
                scope.exclude_path_patterns = [ /exclude/ ]

                subject.exclude?.should be_true
            end
        end

        context 'when self does not match the provided exclude rules' do
            it 'returns false' do
                scope.exclude_path_patterns = [ /boo/ ]

                subject.exclude?.should be_false
            end
        end
    end

    describe '#include?' do
        subject { Arachni::URI.parse( 'http://test.com/include/' ).scope }

        context 'when self matches the provided include rules in' do
            it 'returns true' do
                scope.include_path_patterns = [ /include/ ]
                subject.include?.should be_true
            end
        end

        context 'when self does not match the provided scope_include_path_patterns rules in' do
            it 'returns false' do
                scope.include_path_patterns = [ /boo/ ]
                subject.include?.should be_false
            end
        end
    end

    describe '#in_domain?' do
        let(:url_without_subdomain) { 'http://test.com' }
        let(:url_with_subdomain) { 'http://boo.test.com' }
        let(:url_with_same_subdomain) { 'http://boo.test.com/stuff' }
        let(:url_with_different_subdomain) { 'http://boo2.test.com/stuff' }

        let(:with_subdomain) { Arachni::URI.parse( url_with_subdomain ).scope }
        let(:with_same_subdomain) { Arachni::URI.parse( url_with_same_subdomain ).scope }
        let(:with_different_subdomain) { Arachni::URI.parse( url_with_different_subdomain ).scope }
        let(:without_subdomain) { Arachni::URI.parse( url_without_subdomain ).scope }

        context "when #{Arachni::OptionGroups::Scope}#include_subdomains is" do
            context true do
                before :each do
                    scope.include_subdomains = true
                end

                context "when #{Arachni::Options}#url" do
                    context 'has a subdomain' do
                        before :each do
                            Arachni::Options.url = url_with_subdomain
                        end

                        context 'and the url has a different subdomain' do
                            it 'return true' do
                                with_different_subdomain.in_domain?.should be_true
                            end
                        end

                        context 'and the url has the same subdomain' do
                            it 'return true' do
                                with_same_subdomain.in_domain?.should be_true
                            end
                        end

                        context 'and the url has no subdomain' do
                            it 'return true' do
                                without_subdomain.in_domain?.should be_true
                            end
                        end
                    end

                    context 'has no a subdomain' do
                        before :each do
                            Arachni::Options.url = url_without_subdomain
                        end

                        context 'and the url has a subdomain' do
                            it 'return true' do
                                with_subdomain.in_domain?.should be_true
                            end
                        end

                        context 'and the url has no subdomain' do
                            it 'return true' do
                                without_subdomain.in_domain?.should be_true
                            end
                        end
                    end
                end
            end

            context false do
                before :each do
                    scope.include_subdomains = false
                end

                context "when #{Arachni::Options}#url" do
                    context 'has a subdomain' do
                        before :each do
                            Arachni::Options.url = url_with_subdomain
                        end

                        context 'and the url has a different subdomain' do
                            it 'return false' do
                                with_different_subdomain.in_domain?.should be_false
                            end
                        end

                        context 'and the url has the same subdomain' do
                            it 'return true' do
                                with_same_subdomain.in_domain?.should be_true
                            end
                        end

                        context 'and the url has no subdomain' do
                            it 'return false' do
                                without_subdomain.in_domain?.should be_false
                            end
                        end
                    end

                    context 'has no a subdomain' do
                        before :each do
                            Arachni::Options.url = url_without_subdomain
                        end

                        context 'and the url has a subdomain' do
                            it 'return false' do
                                with_subdomain.in_domain?.should be_false
                            end
                        end

                        context 'and the url has no subdomain' do
                            it 'return true' do
                                without_subdomain.in_domain?.should be_true
                            end
                        end
                    end
                end
            end
        end
    end

    describe '#follow_protocol?' do
        let(:http) { Arachni::URI.parse( 'http://test2.com/blah/ha' ).scope }
        let(:https) { Arachni::URI.parse( 'https://test2.com/blah/ha' ).scope }
        let(:other) { Arachni::URI.parse( 'stuff://test2.com/blah/ha' ).scope }

        context 'when the reference URL uses' do
            context 'HTTPS' do
                before :each do
                    Arachni::Options.url = 'https://test2.com/blah/ha'
                end

                context 'and the checked URL uses' do
                    context 'HTTPS' do
                        context 'and Options#scope_https_only is' do
                            context true do
                                it 'returns true' do
                                    scope.https_only = true
                                    https.follow_protocol?.should be_true
                                end
                            end

                            context false do
                                it 'returns true' do
                                    scope.https_only = false
                                    https.follow_protocol?.should be_true
                                end
                            end
                        end
                    end

                    context 'HTTP' do
                        context 'and Options#scope_https_only is' do
                            context true do
                                it 'returns false' do
                                    scope.https_only = true
                                    http.follow_protocol?.should be_false
                                end
                            end

                            context false do
                                it 'returns true' do
                                    scope.https_only = false
                                    http.follow_protocol?.should be_true
                                end
                            end
                        end
                    end
                end
            end

            context 'HTTP' do
                before :each do
                    Arachni::Options.url = 'http://test2.com/blah/ha'
                end

                context 'and the checked URL uses' do
                    context 'HTTPS' do
                        context 'and Options#scope_https_only is' do
                            context true do
                                it 'returns true' do
                                    scope.https_only = true
                                    https.follow_protocol?.should be_true
                                end
                            end

                            context false do
                                it 'returns true' do
                                    scope.https_only = false
                                    https.follow_protocol?.should be_true
                                end
                            end
                        end
                    end
                    context 'HTTP' do
                        context 'and Options#scope_https_only is' do
                            context true do
                                it 'returns true' do
                                    scope.https_only = true
                                    http.follow_protocol?.should be_true
                                end
                            end

                            context false do
                                it 'returns true' do
                                    scope.https_only = false
                                    http.follow_protocol?.should be_true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    describe '#in?' do
        subject { Arachni::URI.parse( 'http://stuff/' ).scope }

        it 'returns true' do
            subject.should be_in
        end

        context 'when #out?' do
            context 'is true' do
                it 'returns false' do
                    subject.stub(:out?) { true }
                    subject.should_not be_in
                end
            end
        end
    end

    describe '#out?' do
        subject { Arachni::URI.parse( 'http://stuff/' ).scope }

        it 'returns false' do
            subject.should_not be_out
        end

        it 'does not call #redundant?' do
            subject.should_not receive(:redundant?)
            subject.out?
        end

        context 'when #follow_protocol?' do
            context 'is false' do
                it 'returns true' do
                    subject.stub(:follow_protocol?) { false }
                    subject.should be_out
                end
            end
        end

        context 'when #in_domain?' do
            context 'is false' do
                it 'returns true' do
                    subject.stub(:in_domain?) { false }
                    subject.should be_out
                end
            end
        end

        context 'when #too_deep?' do
            context 'is true' do
                it 'returns true' do
                    subject.stub(:too_deep?) { true }
                    subject.should be_out
                end
            end
        end

        context 'when #include?' do
            context 'is false' do
                it 'returns true' do
                    subject.stub(:include?) { false }
                    subject.should be_out
                end
            end
        end

        context 'when #exclude?' do
            context 'is true' do
                it 'returns true' do
                    subject.stub(:exclude?) { true }
                    subject.should be_out
                end
            end
        end
    end

end
