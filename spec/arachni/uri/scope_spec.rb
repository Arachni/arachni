require 'spec_helper'

describe Arachni::URI::Scope do

    before :each do
        Arachni::Options.reset
    end

    let(:scope){ Arachni::Options.scope }

    describe '#too_deep?' do
        subject { Arachni::URI.parse( '/very/very/very/very/deep' ).scope }

        context 'when the directory depth of the URL\'s path is' do
            context 'not greater than the provided depth' do
                it 'returns false' do
                    subject.too_deep?( -1 ).should be_false

                    scope.directory_depth_limit = 100
                    subject.too_deep?( 100 ).should be_false
                end
            end

            context 'greater than the provided depth' do
                it 'returns true' do
                    subject.too_deep?( 2 ).should be_true
                end
            end
        end

        context 'when called without argument' do
            it "uses #{Arachni::OptionGroups::Scope}#directory_depth_limit"
        end
    end

    describe '#redundant?' do
        subject { Arachni::URI.parse( 'http://stuff.com/match_this' ).scope }

        context "when a URL's counter reaches 0" do
            it 'returns true' do
                scope.redundant_path_patterns = { /match_this/ => 10 }

                10.times do
                    subject.redundant?.should be_false
                end

                subject.redundant?.should be_true
            end
        end
        context "when a URL's counter has not reached 0" do
            it 'returns false' do
                scope.redundant_path_patterns = { /match_this/ => 11 }

                10.times do
                    subject.redundant?.should be_false
                end

                subject.redundant?.should be_false
            end
        end
    end

    describe '#exclude?' do
        subject { Arachni::URI.parse( 'http://test.com/exclude/' ).scope }

        context 'when self matches the provided exclude rules' do
            it 'returns true' do
                rules = [ /exclude/ ]
                subject.exclude?( rules ).should be_true

                subject.exclude?( rules.first ).should be_true
            end
        end

        context 'when self does not match the provided exclude rules' do
            it 'returns false' do
                rules = [ /boo/ ]
                subject.exclude?( rules ).should be_false

                subject.exclude?( rules.first ).should be_false
            end
        end

        context 'when the provided rules are nil' do
            it 'raises a ArgumentError' do
                expect { subject.exclude?( nil ) }.to raise_error ArgumentError
            end
        end

        context 'when called without argument' do
            it "uses #{Arachni::OptionGroups::Scope}#exclude_path_patterns"
        end
    end

    describe '#include?' do
        subject { Arachni::URI.parse( 'http://test.com/include/' ).scope }

        context 'when self matches the provided include rules in' do
            it 'returns true' do
                rules = [ /include/ ]
                subject.include?( rules ).should be_true

                subject.include?( rules.first ).should be_true
            end
        end

        context 'when self does not match the provided scope_include_path_patterns rules in' do
            it 'returns false' do
                rules = [ /boo/ ]
                subject.include?( rules ).should be_false

                subject.include?( rules.first ).should be_false
            end
        end

        context 'when the provided rules are empty' do
            it 'returns true' do
                subject.include?( [] ).should be_true
            end
        end

        context 'when the provided rules are nil' do
            it 'raises a ArgumentError' do
                expect { subject.include?( nil ) }.to raise_error ArgumentError
            end
        end

        context 'when called without argument' do
            it "uses #{Arachni::OptionGroups::Scope}#include_path_patterns"
        end
    end

    describe '#in_domain?' do
        subject { Arachni::URI.parse( 'http://test.com/' ).scope }
        let(:with_subdomain) { Arachni::URI.parse( 'http://boo.test.com' ) }
        let(:without_subdomain) { Arachni::URI.parse( 'http://test.com' ) }

        context 'when include_subdomains is' do
            context true do
                it 'includes subdomains in the comparison' do
                    subject.in_domain?( with_subdomain, true ).should be_false
                    subject.in_domain?( without_subdomain, true ).should be_true
                end
            end
            context false do
                it 'does not include subdomains in the comparison' do
                    subject.in_domain?( with_subdomain, false ).should be_true
                    subject.in_domain?( without_subdomain, true ).should be_true
                end
            end
        end

        context 'when called without argument' do
            it "uses #{Arachni::Options}#url for reference URL"
            it "uses #{Arachni::OptionGroups::Scope}#include_subdomains to determine subdomain consideration"
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

end
