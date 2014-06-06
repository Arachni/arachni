require 'spec_helper'

describe Arachni::HTTP::Response::Scope do

    before :each do
        Arachni::Options.reset
    end

    let(:scope){ Arachni::Options.scope }
    let(:response) { Factory[:response] }
    subject { response.scope }

    describe '#exclude?' do
        context 'when #text?' do
            context true do
                context "and #{Arachni::OptionGroups::Scope}#exclude_binaries?" do
                    context true do
                        it 'returns false' do
                            scope.exclude_binaries = true
                            response.stub(:text?) { true }

                            subject.exclude?.should be_false
                        end
                    end

                    context false do
                        it 'returns false' do
                            scope.exclude_binaries = false
                            response.stub(:text?) { true }

                            subject.exclude?.should be_false
                        end
                    end
                end
            end

            context false do
                context "and #{Arachni::OptionGroups::Audit}#exclude_binaries?" do
                    context true do
                        it 'returns true' do
                            scope.exclude_binaries = true
                            response.stub(:text?) { false }

                            subject.exclude?.should be_true
                        end
                    end

                    context false do
                        it 'returns false' do
                            scope.exclude_binaries = false
                            response.stub(:text?) { false }

                            subject.exclude?.should be_false
                        end
                    end
                end
            end
        end

        context 'when #exclude_content?' do
            context true do
                it 'returns true' do
                    subject.stub(:exclude_content?) { true }
                    subject.exclude?.should be_true
                end
            end

            context false do
                it 'returns false' do
                    subject.stub(:exclude_content?) { false }
                    subject.exclude?.should be_false
                end
            end
        end
    end

    describe '#exclude_content?' do
        context "when #{Arachni::OptionGroups::Scope}#exclude_content_patterns" do
            context 'match the #body' do
                it 'returns true' do
                    scope.exclude_content_patterns = /<a/
                    subject.exclude?.should be_true
                end
            end

            context 'do not match the #body' do
                it 'returns false' do
                    subject.exclude?.should be_false

                    scope.exclude_content_patterns = /<blah/
                    subject.exclude?.should be_false
                end
            end
        end
    end
end
