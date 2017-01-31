require 'spec_helper'

describe Arachni::Support::Signature do
    def string_with_noise
        <<-END
                This #{rand(999999)} is a test.
                Not #{rand(999999)} really sure what #{rand(999999)} else to put here...
                #{rand(999999)}
        END
    end

    def different_string_with_noise
        <<-END
                This #{rand(999999)} is a different test.
        END
    end

    let(:signature) { described_class.new( string_with_noise ) }

    describe '#initialize' do
        describe 'option' do
            describe ':threshold' do
                it 'sets the maximum difference ratio when performing comparisons' do
                    seed1 = 'test this here 1'
                    seed2 = 'test that here 2'

                    s  = described_class.new( seed1, threshold: 0.01 )
                    s1 = described_class.new( seed2 )
                    expect(s).not_to be_similar s1

                    s  = described_class.new( seed1, threshold: 0.1 )
                    s1 = described_class.new( seed2 )
                    expect(s).not_to be_similar s1

                    s  = described_class.new( seed1, threshold: 0.7 )
                    s1 = described_class.new( seed2 )
                    expect(s).to be_similar s1

                    s  = described_class.new( seed1, threshold: 1 )
                    s1 = described_class.new( seed2 )
                    expect(s).to be_similar s1
                end

                context 'when not a number' do
                    it 'raises ArgumentError' do
                        expect do
                            described_class.new( 'test', threshold: 'stuff' )
                        end.to raise_error ArgumentError
                    end
                end
            end
        end
    end

    describe '#refine' do
        it 'removes noise from the signature' do
            expect(string_with_noise).not_to eq(string_with_noise)

            signature1 = described_class.new( string_with_noise )

            10.times{ signature1 = signature1.refine( string_with_noise ) }

            signature2 = described_class.new( string_with_noise )
            10.times{ signature2 = signature2.refine( string_with_noise ) }

            expect(signature1).to eq(signature2)
        end

        it 'returns a new signature instance' do
            signature1 = described_class.new( string_with_noise )
            expect(signature1.refine( string_with_noise ).object_id).not_to eq(signature1.object_id)
        end
    end

    describe '#refine!' do
        it 'destructively removes noise from the signature' do
            expect(string_with_noise).not_to eq(string_with_noise)

            signature1 = described_class.new( string_with_noise )
            10.times{ signature1.refine!( string_with_noise ) }

            signature2 = described_class.new( string_with_noise )
            10.times{ signature2.refine!( string_with_noise ) }

            expect(signature1).to eq(signature2)
        end

        it 'returns self' do
            signature = described_class.new( string_with_noise )
            expect(signature.refine!( string_with_noise ).object_id).to eq(signature.object_id)
        end

        it 'resets #hash' do
            signature = described_class.new( string_with_noise )

            ph = signature.hash

            signature.refine!( string_with_noise )
            h = signature.hash

            expect(ph).not_to eq h
        end
    end

    describe '#<<' do
        it 'pushes new data to the signature' do
            string = string_with_noise
            d1 = string.lines[0..-3].join
            d2 = string.lines[-2..-1].join

            signature = described_class.new( d1 )
            t1 = signature.tokens.dup

            signature << d2

            t2 = signature.tokens.dup

            expect(t1).to be_subset t2
        end

        it 'returns self' do
            signature = described_class.new( string_with_noise )
            expect((signature << string_with_noise ).object_id).to eq(signature.object_id)
        end

        it 'resets #hash' do
            signature = described_class.new( string_with_noise )

            ph = signature.hash

            signature << string_with_noise
            h = signature.hash

            expect(ph).not_to eq h
        end
    end

    describe '#differences' do
        it 'returns ratio of differences between signatures' do
            signature1 = described_class.new( string_with_noise )
            signature2 = described_class.new( string_with_noise )
            signature3 = described_class.new( different_string_with_noise )
            signature4 = described_class.new( different_string_with_noise )

            expect(signature1.differences( signature2 ).round(3)).to eq(0.4)
            expect(signature2.differences( signature2 )).to eq(0)

            expect(signature3.differences( signature4 ).round(3)).to eq(0.286)
            expect(signature4.differences( signature4 )).to eq(0)
            expect(signature1.differences( signature3 ).round(3)).to eq(0.778)
        end
    end

    describe '#empty?' do
        context 'when the signature is empty' do
            subject { described_class.new( '' ) }

            expect_it { to be_empty }
        end

        context 'when the signature is not empty' do
            subject { described_class.new( string_with_noise ) }

            expect_it { to_not be_empty }
        end
    end

    describe '#==' do
        context 'when the signature are identical' do
            it 'returns true' do
                signature1 = described_class.new( string_with_noise )
                10.times{ signature1.refine!( string_with_noise ) }

                signature2 = described_class.new( string_with_noise )
                10.times{ signature2.refine!( string_with_noise ) }

                expect(signature1).to eq(signature2)
            end
        end

        context 'when the signature are not identical' do
            it 'returns false' do
                signature1 = described_class.new( string_with_noise )
                10.times{ signature1.refine!( string_with_noise ) }

                signature2 = described_class.new( different_string_with_noise )
                10.times{ signature2.refine!( different_string_with_noise ) }

                expect(signature1).not_to eq(signature2)
            end
        end
    end

    describe '#dup' do
        it 'returns a duplicate instance' do
            expect(signature.dup).to eq(signature)
            expect(signature.dup.object_id).not_to eq(signature.object_id)
        end
    end
end
