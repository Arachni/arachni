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
        it 'initializes the signature with seed data' do
            described_class.new( '' ).tokens.should be_empty
            described_class.new( string_with_noise ).tokens.should be_any
        end

        describe 'option' do
            describe :threshold do
                it 'sets the maximum difference in tokens when performing comparisons' do
                    seed1 = 'test this here 1'
                    seed2 = 'test that here 2'

                    s  = described_class.new( seed1, threshold: 1 )
                    s1 = described_class.new( seed2 )
                    s.should_not == s1

                    s  = described_class.new( seed1, threshold: 2 )
                    s1 = described_class.new( seed2 )
                    s.should_not == s1

                    s  = described_class.new( seed1, threshold: 3 )
                    s1 = described_class.new( seed2 )
                    s.should == s1

                    s  = described_class.new( seed1, threshold: 4 )
                    s1 = described_class.new( seed2 )
                    s.should == s1
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
            string_with_noise.should_not == string_with_noise

            signature1 = described_class.new( string_with_noise )

            10.times{ signature1 = signature1.refine( string_with_noise ) }

            signature2 = described_class.new( string_with_noise )
            10.times{ signature2 = signature2.refine( string_with_noise ) }

            signature1.should == signature2
        end

        it 'returns a new signature instance' do
            signature1 = described_class.new( string_with_noise )
            signature1.refine( string_with_noise ).object_id.should_not == signature1
        end
    end

    describe '#refine!' do
        it 'destructively removes noise from the signature' do
            string_with_noise.should_not == string_with_noise

            signature1 = described_class.new( string_with_noise )
            10.times{ signature1.refine!( string_with_noise ) }

            signature2 = described_class.new( string_with_noise )
            10.times{ signature2.refine!( string_with_noise ) }

            signature1.should == signature2
        end

        it 'returns self' do
            signature = described_class.new( string_with_noise )
            signature.refine!( string_with_noise ).object_id.should == signature.object_id
        end
    end

    describe '#==' do
        context 'when the signature are identical' do
            it 'returns true' do
                signature1 = described_class.new( string_with_noise )
                10.times{ signature1.refine!( string_with_noise ) }

                signature2 = described_class.new( string_with_noise )
                10.times{ signature2.refine!( string_with_noise ) }

                signature1.should == signature2
            end
        end

        context 'when the signature are identical' do
            it 'returns true' do
                signature1 = described_class.new( string_with_noise )
                10.times{ signature1.refine!( string_with_noise ) }

                signature2 = described_class.new( different_string_with_noise )
                10.times{ signature2.refine!( different_string_with_noise ) }

                signature1.should_not == signature2
            end
        end
    end

    describe '#dup' do
        it 'returns a duplicate instance' do
            signature.dup.should == signature
            signature.dup.object_id.should_not == signature.object_id
        end
    end
end
