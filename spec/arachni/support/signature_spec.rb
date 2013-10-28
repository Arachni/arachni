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

    describe '#refine' do
        it 'removes noise from the signature' do
            string_with_noise.should_not == string_with_noise

            signature1 = described_class.new( string_with_noise )
            10.times{ signature1.refine( string_with_noise ) }

            signature2 = described_class.new( string_with_noise )
            10.times{ signature2.refine( string_with_noise ) }

            signature1.should == signature2
        end
    end

    describe '#==' do
        context 'when the signature are identical' do
            it 'returns true' do
                signature1 = described_class.new( string_with_noise )
                10.times{ signature1.refine( string_with_noise ) }

                signature2 = described_class.new( string_with_noise )
                10.times{ signature2.refine( string_with_noise ) }

                signature1.should == signature2
            end
        end

        context 'when the signature are identical' do
            it 'returns true' do
                signature1 = described_class.new( string_with_noise )
                10.times{ signature1.refine( string_with_noise ) }

                signature2 = described_class.new( different_string_with_noise )
                10.times{ signature2.refine( different_string_with_noise ) }

                signature1.should_not == signature2
            end
        end
    end
end
