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
            expect(subject.out?).to be_falsey
        end

        context "when #{Arachni::URI::Scope}#out?" do
            context 'true' do
                it 'returns true' do
                    # We can't stub #out? because we also override it.
                    allow_any_instance_of(Arachni::URI::Scope).to receive(:exclude?) { true }
                    expect(subject.out?).to be_truthy
                end
            end

            context 'false' do
                it 'returns false' do
                    allow_any_instance_of(Arachni::URI::Scope).to receive(:exclude?) { false }
                    expect(subject.out?).to be_falsey
                end
            end
        end

        context 'when #exclude_as_binary?' do
            context 'true' do
                it 'returns true' do
                    allow(subject).to receive(:exclude_as_binary?) { true }
                    expect(subject.out?).to be_truthy
                end
            end

            context 'false' do
                it 'returns false' do
                    allow(subject).to receive(:exclude_as_binary?) { false }
                    expect(subject.out?).to be_falsey
                end
            end
        end

        context 'when #exclude_content?' do
            context 'true' do
                it 'returns true' do
                    allow(subject).to receive(:exclude_content?) { true }
                    expect(subject.out?).to be_truthy
                end
            end

            context 'false' do
                it 'returns false' do
                    allow(subject).to receive(:exclude_content?) { false }
                    expect(subject.out?).to be_falsey
                end
            end
        end
    end

    describe '#exclude_as_binary?' do
        context 'when #text?' do
            context 'true' do
                context "and #{Arachni::OptionGroups::Scope}#exclude_binaries?" do
                    context 'true' do
                        it 'returns false' do
                            scope.exclude_binaries = true
                            allow(response).to receive(:text?) { true }

                            expect(subject.exclude_as_binary?).to be_falsey
                        end
                    end

                    context 'false' do
                        it 'returns false' do
                            scope.exclude_binaries = false
                            allow(response).to receive(:text?) { true }

                            expect(subject.exclude_as_binary?).to be_falsey
                        end
                    end
                end
            end

            context 'false' do
                context "and #{Arachni::OptionGroups::Audit}#exclude_binaries?" do
                    context 'true' do
                        it 'returns true' do
                            scope.exclude_binaries = true
                            allow(response).to receive(:text?) { false }

                            expect(subject.exclude_as_binary?).to be_truthy
                        end
                    end

                    context 'false' do
                        it 'returns false' do
                            scope.exclude_binaries = false
                            allow(response).to receive(:text?) { false }

                            expect(subject.exclude_as_binary?).to be_falsey
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
                    expect(subject.exclude_content?).to be_truthy
                end
            end

            context 'do not match the #body' do
                it 'returns false' do
                    expect(subject.exclude_content?).to be_falsey

                    scope.exclude_content_patterns = /<blah/
                    expect(subject.exclude_content?).to be_falsey
                end
            end
        end
    end
end
