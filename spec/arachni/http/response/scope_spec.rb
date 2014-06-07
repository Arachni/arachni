require 'spec_helper'

describe Arachni::HTTP::Response::Scope do

    before :each do
        Arachni::Options.reset
    end

    let(:scope){ Arachni::Options.scope }
    let(:response) { Factory[:response] }
    subject { response.scope }

    describe '#out?' do
        it 'returns false' do
            subject.out?.should be_false
        end

        context "when #{Arachni::URI::Scope}#out?" do
            context true do
                it 'returns true' do
                    # We can't stub #out? because we also override it.
                    Arachni::URI::Scope.any_instance.stub(:exclude?) { true }
                    subject.out?.should be_true
                end
            end

            context false do
                it 'returns false' do
                    Arachni::URI::Scope.any_instance.stub(:exclude?) { false }
                    subject.out?.should be_false
                end
            end
        end

        context 'when #exclude_as_binary?' do
            context true do
                it 'returns true' do
                    subject.stub(:exclude_as_binary?) { true }
                    subject.out?.should be_true
                end
            end

            context false do
                it 'returns false' do
                    subject.stub(:exclude_as_binary?) { false }
                    subject.out?.should be_false
                end
            end
        end

        context 'when #exclude_content?' do
            context true do
                it 'returns true' do
                    subject.stub(:exclude_content?) { true }
                    subject.out?.should be_true
                end
            end

            context false do
                it 'returns false' do
                    subject.stub(:exclude_content?) { false }
                    subject.out?.should be_false
                end
            end
        end
    end

    describe '#exclude_as_binary?' do
        context 'when #text?' do
            context true do
                context "and #{Arachni::OptionGroups::Scope}#exclude_binaries?" do
                    context true do
                        it 'returns false' do
                            scope.exclude_binaries = true
                            response.stub(:text?) { true }

                            subject.exclude_as_binary?.should be_false
                        end
                    end

                    context false do
                        it 'returns false' do
                            scope.exclude_binaries = false
                            response.stub(:text?) { true }

                            subject.exclude_as_binary?.should be_false
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

                            subject.exclude_as_binary?.should be_true
                        end
                    end

                    context false do
                        it 'returns false' do
                            scope.exclude_binaries = false
                            response.stub(:text?) { false }

                            subject.exclude_as_binary?.should be_false
                        end
                    end
                end
            end
        end
    end

    describe '#exclude_content?' do
        context "when #{Arachni::OptionGroups::Scope}#exclude_content_patterns" do
            context 'match the #body' do
                it 'returns true' do
                    scope.exclude_content_patterns = /<a/
                    subject.exclude_content?.should be_true
                end
            end

            context 'do not match the #body' do
                it 'returns false' do
                    subject.exclude_content?.should be_false

                    scope.exclude_content_patterns = /<blah/
                    subject.exclude_content?.should be_false
                end
            end
        end
    end
end
