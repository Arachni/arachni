require 'spec_helper'

shared_examples_for 'cache' do
    subject { described_class.new }

    describe '#new' do
        describe 'max_size' do
            describe 'nil' do
                it 'leaves the cache uncapped' do
                    described_class.new.capped?.should be_false
                end
            end
            describe Integer do
                it 'imposes a limit to the size of the cache' do
                    described_class.new( 10 ).capped?.should be_true
                end
            end
        end
    end

    describe '#max_size' do
        context 'when just initialized' do
            it 'returns nil (unlimited)' do
                subject.max_size.should be_nil
            end
        end
        context 'when set' do
            it 'returns the set value' do
                (subject.max_size = 50).should == 50
                subject.max_size.should == 50
            end
        end
    end

    describe '#uncap' do
        it 'removes the size limit' do
            subject.max_size = 1
            subject.uncap
            subject.max_size = nil
        end
    end

    describe '#capped?' do
        context 'when the cache has no size limit' do
            it 'returns false' do
                subject.uncap
                subject.capped?.should be_false
                subject.max_size.should be_nil
            end
        end
        context 'when the cache has a size limit' do
            it 'returns true' do
                subject.max_size = 1
                subject.capped?.should be_true
            end
        end
    end

    describe '#uncapped?' do
        context 'when the cache has no size limit' do
            it 'returns true' do
                subject.uncap
                subject.uncapped?.should be_true
                subject.max_size.should be_nil
            end
        end
        context 'when the cache has a size limit' do
            it 'returns false' do
                subject.max_size = 1
                subject.max_size.should == 1
                subject.uncapped?.should be_false
            end
        end
    end

    describe '#uncap' do
        it 'removes the size limit' do
            subject.max_size = 1
            subject.uncapped?.should be_false
            subject.max_size.should == 1

            subject.uncap
            subject.uncapped?.should be_true
            subject.max_size.should be_nil
        end
    end

    describe '#max_size=' do
        it 'sets the maximum size for the cache' do
            (subject.max_size = 100).should == 100
            subject.max_size.should == 100
        end

        context 'when passed < 0' do
            it 'throwes an exception' do
                raised = false
                begin
                    subject.max_size = 0
                rescue
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#size' do
        context 'when the cache is empty' do
            it 'returns 0' do
                subject.size.should == 0
            end
        end

        context 'when the cache is not empty' do
            it 'returns a value > 0' do
                subject['stuff'] = [ 'ff ' ]
                subject.size.should > 0
            end
        end
    end

    describe '#empty?' do
        context 'when the cache is empty' do
            it 'returns true' do
                subject.empty?.should be_true
            end
        end
        context 'when the cache is not empty' do
            it 'returns false' do
                subject['stuff2'] = 'ff'
                subject.empty?.should be_false
            end
        end
    end

    describe '#any?' do
        context 'when the cache is empty' do
            it 'returns true' do
                subject.any?.should be_false
            end
        end
        context 'when the cache is not empty' do
            it 'returns false' do
                subject['stuff3'] = [ 'ff ' ]
                subject.any?.should be_true
            end
        end
    end

    describe '#[]=' do
        it 'stores an object' do
            v = 'val'
            (subject[:key] = v).should == v
            subject[:key].should == v
        end
        it 'is alias of #store' do
            v = 'val2'
            subject.store( :key2, v ).should == v
            subject[:key2].should == v
        end
    end

    describe '#[]' do
        it 'retrieves an object by key' do
            v = 'val2'
            subject[:key] = v
            subject[:key].should == v
            subject.empty?.should be_false
        end

        context 'when the key does not exist' do
            it 'returns nil' do
                subject[:some_key].should be_nil
            end
        end
    end

    describe '#fetch_or_store' do
        context 'when the passed key exists' do
            it 'returns its value' do
                old_val = 'my val'
                new_val = 'new val'

                cache = described_class.new
                cache[:my_key] = old_val
                cache.fetch_or_store( :my_key ) { new_val }

                cache[:my_key].should == old_val
            end
        end

        context 'when the passed key does not exist' do
            it 'assigns to it the return value of the given block' do
                new_val = 'new val'
                cache = described_class.new
                cache.fetch_or_store( :my_key ) { new_val }

                cache[:my_key].should == new_val
            end
        end
    end

    describe '#include?' do
        context 'when the key exists' do
            it 'returns true' do
                subject[:key1] = 'v'
                subject.include?( :key1 ).should be_true
            end
        end
        context 'when the key does not exist' do
            it 'returns false' do
                subject.include?( :key2 ).should be_false
            end
        end
    end

    describe '#delete' do
        context 'when the key exists' do
            it 'deletes a key' do
                v = 'my_val'
                subject[:my_key] = v
                subject.delete( :my_key ).should == v
                subject[:my_key].should be_nil
                subject.include?( :my_key ).should be_false
            end
            it 'returns its value' do
                v = 'my_val'
                subject[:my_key] = v
                subject.delete( :my_key ).should == v
                subject[:my_key].should be_nil
                subject.include?( :my_key ).should be_false
            end
        end
        context 'when the key does not exist' do
            it 'should return nil' do
                subject.delete( :my_key2 ).should be_nil
            end
        end
    end

    describe '#empty?' do
        context 'when cache is empty' do
            it 'returns true' do
                subject.empty?.should be_true
            end
        end
        context 'when cache is not empty' do
            it 'returns false' do
                subject['ee'] = 'rr'
                subject.empty?.should be_false
            end
        end
    end

    describe '#any?' do
        context 'when cache is empty' do
            it 'returns false' do
                subject.any?.should be_false
            end
        end
        context 'when cache is not empty' do
            it 'returns true' do
                subject['ee'] = 'rr'
                subject.any?.should be_true
            end
        end
    end

    describe '#clear' do
        it 'empties the cache' do
            subject[:my_key2] = 'v'
            subject.size.should > 0
            subject.empty?.should be_false
            subject.clear

            subject.size.should == 0
            subject.empty?.should be_true
        end
    end

    describe '#==' do
        context 'when 2 lists are equal' do
            it 'returns true' do
                new = described_class.new

                subject[:test_key] = 'test_val'
                new[:test_key]     = 'test_val'

                subject.should == new
            end
        end

        context 'when 2 lists are not equal' do
            it 'returns false' do
                new = described_class.new

                subject[:test_key] = 'test_val'
                new[:test_key]     = 'test_val2'

                subject.should_not == new
            end
        end
    end

    describe '#hash' do
        context 'when 2 lists are equal' do
            it 'returns the same value' do
                new = described_class.new

                subject[:test_key] = 'test_val'
                new[:test_key]     = 'test_val'

                subject.hash.should == new.hash
            end
        end

        context 'when 2 lists are not equal' do
            it 'returns different values' do
                new = described_class.new

                subject[:test_key] = 'test_val'
                new[:test_key]     = 'test_val2'

                subject.hash.should_not == new.hash
            end
        end
    end

    describe '#dup' do
        it 'returns a copy' do
            subject[:test_key] = 'test_val'
            copy = subject.dup

            copy.should == subject

            copy[:test_key] = 'test_val2'

            copy.should_not == subject
        end
    end
end
