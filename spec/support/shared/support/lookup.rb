require 'spec_helper'

shared_examples_for 'lookup' do
    subject { described_class.new }

    it { should respond_to :collection }

    describe '#<<' do
        it 'adds an object and return self' do
            (subject << 'test').should == subject
        end
        it 'aliased to #add' do
            subject.add( 'test2' ).should == subject
        end
    end

    describe '#include?' do
        context 'when an object is included' do
            it 'returns true' do
                subject << 'test'
                subject << 'test2'

                subject.include?( 'test' ).should be_true
                subject.include?( 'test2' ).should be_true
            end
        end
        context 'when an object is not included' do
            it 'returns false' do
                subject.include?( 'test3' ).should be_false
            end
        end
    end

    describe '#delete?' do
        it 'deletes an object and return self' do
            subject << 'test'

            subject.include?( 'test' ).should be_true
            subject.delete( 'test' ).should be_true
            subject.include?( 'test' ).should be_false
        end
    end

    describe '#empty?' do
        context 'when empty' do
            it 'returns true' do
                subject.empty?.should be_true
            end
        end
        context 'when not empty' do
            it 'returns false' do
                subject << 'test'
                subject.empty?.should be_false
            end
        end
    end

    describe '#any?' do
        context 'when empty' do
            it 'returns false' do
                subject.any?.should be_false
            end
        end
        context 'when not empty' do
            it 'returns true' do
                subject << 'test'
                subject.any?.should be_true
            end
        end
    end

    describe '#size' do
        it 'returns the size' do
            bf = described_class.new
            bf.size.should == 0
            bf << '1'
            bf.size.should == 1
            bf << '1'
            bf.size.should == 1
            bf << '2'
            bf.size.should == 2
        end
    end

    describe '#clear' do
        it 'empties the list' do
            bf = described_class.new
            bf << '1'
            bf << '2'
            bf.size.should == 2
            bf.clear
            bf.size.should == 0
        end
    end

    describe '#==' do
        context 'when 2 lists are equal' do
            it 'returns true' do
                new = described_class.new

                subject << 'test'
                new     << 'test'

                subject.should == new
            end
        end

        context 'when 2 lists are not equal' do
            it 'returns false' do
                new = described_class.new

                subject << 'test'
                new     << 'test2'

                subject.should_not == new
            end
        end
    end

    describe '#hash' do
        context 'when 2 lists are equal' do
            it 'returns the same value' do
                new = described_class.new

                subject << 'test'
                new     << 'test'

                subject.hash.should == new.hash
            end
        end

        context 'when 2 lists are not equal' do
            it 'returns different values' do
                new = described_class.new

                subject << 'test'
                new     << 'test2'

                subject.hash.should_not == new.hash
            end
        end
    end

    describe '#dup' do
        it 'returns a copy' do
            subject << 'test'
            copy = subject.dup

            copy.should == subject

            copy << 'test2'

            copy.should_not == subject
        end
    end
end
