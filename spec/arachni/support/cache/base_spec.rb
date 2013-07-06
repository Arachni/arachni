require 'spec_helper'

describe Arachni::Support::Cache::Base do

    before { @cache = described_class.new }

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
                @cache.max_size.should be_nil
            end
        end
        context 'when set' do
            it 'returns the set value' do
                (@cache.max_size = 50).should == 50
                @cache.max_size.should == 50
            end
        end
    end

    describe '#uncap' do
        it 'removes the size limit' do
            @cache.max_size = 1
            @cache.uncap
            @cache.max_size = nil
        end
    end

    describe '#capped?' do
        context 'when the cache has no size limit' do
            it 'returns false' do
                @cache.uncap
                @cache.capped?.should be_false
                @cache.max_size.should be_nil
            end
        end
        context 'when the cache has a size limit' do
            it 'returns true' do
                @cache.max_size = 1
                @cache.capped?.should be_true
            end
        end
    end

    describe '#uncapped?' do
        context 'when the cache has no size limit' do
            it 'returns true' do
                @cache.uncap
                @cache.uncapped?.should be_true
                @cache.max_size.should be_nil
            end
        end
        context 'when the cache has a size limit' do
            it 'returns false' do
                @cache.max_size = 1
                @cache.max_size.should == 1
                @cache.uncapped?.should be_false
            end
        end
    end

    describe '#uncap' do
        it 'removes the size limit' do
            @cache.max_size = 1
            @cache.uncapped?.should be_false
            @cache.max_size.should == 1

            @cache.uncap
            @cache.uncapped?.should be_true
            @cache.max_size.should be_nil
        end
    end

    describe '#max_size=' do
        it 'sets the maximum size for the cache' do
            (@cache.max_size = 100).should == 100
            @cache.max_size.should == 100
        end

        context 'when passed < 0' do
            it 'throwes an exception' do
                raised = false
                begin
                    @cache.max_size = 0
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
                @cache.size.should == 0
            end
        end

        context 'when the cache is not empty' do
            it 'returns a value > 0' do
                @cache['stuff'] = [ 'ff ' ]
                @cache.size.should > 0
            end
        end
    end

    describe '#empty?' do
        context 'when the cache is empty' do
            it 'returns true' do
                @cache.empty?.should be_true
            end
        end
        context 'when the cache is not empty' do
            it 'returns false' do
                @cache['stuff2'] = 'ff'
                @cache.empty?.should be_false
            end
        end
    end

    describe '#any?' do
        context 'when the cache is empty' do
            it 'returns true' do
                @cache.any?.should be_false
            end
        end
        context 'when the cache is not empty' do
            it 'returns false' do
                @cache['stuff3'] = [ 'ff ' ]
                @cache.any?.should be_true
            end
        end
    end

    describe '#[]=' do
        it 'stores an object' do
            v = 'val'
            (@cache[:key] = v).should == v
            @cache[:key].should == v
        end
        it 'is alias of #store' do
            v = 'val2'
            @cache.store( :key2, v ).should == v
            @cache[:key2].should == v
        end
    end

    describe '#[]' do
        it 'retrieves an object by key' do
            v = 'val2'
            @cache[:key] = v
            @cache[:key].should == v
            @cache.empty?.should be_false
        end

        context 'when the key does not exist' do
            it 'returns nil' do
                @cache[:some_key].should be_nil
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
                @cache[:key1] = 'v'
                @cache.include?( :key1 ).should be_true
            end
        end
        context 'when the key does not exist' do
            it 'returns false' do
                @cache.include?( :key2 ).should be_false
            end
        end
    end

    describe '#delete' do
        context 'when the key exists' do
            it 'deletes a key' do
                v = 'my_val'
                @cache[:my_key] = v
                @cache.delete( :my_key ).should == v
                @cache[:my_key].should be_nil
                @cache.include?( :my_key ).should be_false
            end
            it 'returns its value' do
                v = 'my_val'
                @cache[:my_key] = v
                @cache.delete( :my_key ).should == v
                @cache[:my_key].should be_nil
                @cache.include?( :my_key ).should be_false
            end
        end
        context 'when the key does not exist' do
            it 'should return nil' do
                @cache.delete( :my_key2 ).should be_nil
            end
        end
    end

    describe '#empty?' do
        context 'when cache is empty' do
            it 'returns true' do
                @cache.empty?.should be_true
            end
        end
        context 'when cache is not empty' do
            it 'returns false' do
                @cache['ee'] = 'rr'
                @cache.empty?.should be_false
            end
        end
    end

    describe '#any?' do
        context 'when cache is empty' do
            it 'returns false' do
                @cache.any?.should be_false
            end
        end
        context 'when cache is not empty' do
            it 'returns true' do
                @cache['ee'] = 'rr'
                @cache.any?.should be_true
            end
        end
    end

    describe '#clear' do
        it 'empties the cache' do
            @cache[:my_key2] = 'v'
            @cache.size.should > 0
            @cache.empty?.should be_false
            @cache.clear

            @cache.size.should == 0
            @cache.empty?.should be_true
        end
    end

end
