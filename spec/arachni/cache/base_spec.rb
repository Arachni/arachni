require_relative '../../spec_helper'

describe Arachni::Cache::Base do

    before { @cache = Arachni::Cache::Base.new }

    describe '#new' do
        describe 'max_size' do
            describe 'nil' do
                it 'should leave the cache uncapped' do
                    Arachni::Cache::Base.new.capped?.should be_false
                end
            end
            describe Integer do
                it 'should impose a limit to the size of the cache' do
                    Arachni::Cache::Base.new( 10 ).capped?.should be_true
                end
            end
        end
    end

    describe '#max_size' do
        context 'when just initialized' do
            it 'should return nil (unlimited)' do
                @cache.max_size.should be_nil
            end
        end
        context 'when set' do
            it 'should return the set value' do
                (@cache.max_size = 50).should == 50
                @cache.max_size.should == 50
            end
        end
    end

    describe '#uncap' do
        it 'should remove the size limit' do
            @cache.max_size = 1
            @cache.uncap
            @cache.max_size = nil
        end
    end

    describe '#capped?' do
        context 'when the cache has no size limit' do
            it 'should return false' do
                @cache.uncap
                @cache.capped?.should be_false
                @cache.max_size.should be_nil
            end
        end
        context 'when the cache has a size limit' do
            it 'should return true' do
                @cache.max_size = 1
                @cache.capped?.should be_true
            end
        end
    end

    describe '#uncapped?' do
        context 'when the cache has no size limit' do
            it 'should return true' do
                @cache.uncap
                @cache.uncapped?.should be_true
                @cache.max_size.should be_nil
            end
        end
        context 'when the cache has a size limit' do
            it 'should return false' do
                @cache.max_size = 1
                @cache.max_size.should == 1
                @cache.uncapped?.should be_false
            end
        end
    end

    describe '#uncap' do
        it 'should remove the size limit' do
            @cache.max_size = 1
            @cache.uncapped?.should be_false
            @cache.max_size.should == 1

            @cache.uncap
            @cache.uncapped?.should be_true
            @cache.max_size.should be_nil
        end
    end

    describe '#max_size=' do
        it 'should set the maximum size for the cache' do
            (@cache.max_size = 100).should == 100
            @cache.max_size.should == 100
        end

        context 'when passed < 0' do
            it 'should throw an exception' do
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
            it 'should return 0' do
                @cache.size.should == 0
            end
        end

        context 'when the cache is not empty' do
            it 'should return a value > 0' do
                @cache['stuff'] = [ 'ff ' ]
                @cache.size.should > 0
            end
        end
    end

    describe '#empty?' do
        context 'when the cache is empty' do
            it 'should return true' do
                @cache.empty?.should be_true
            end
        end
        context 'when the cache is not empty' do
            it 'should return false' do
                @cache['stuff2'] = 'ff'
                @cache.empty?.should be_false
            end
        end
    end

    describe '#any?' do
        context 'when the cache is empty' do
            it 'should return true' do
                @cache.any?.should be_false
            end
        end
        context 'when the cache is not empty' do
            it 'should return false' do
                @cache['stuff3'] = [ 'ff ' ]
                @cache.any?.should be_true
            end
        end
    end

    describe '#[]=' do
        it 'should store an object' do
            v = 'val'
            (@cache[:key] = v).should == v
            @cache[:key].should == v
        end
        it 'should be an alias of #store' do
            v = 'val2'
            @cache.store( :key2, v ).should == v
            @cache[:key2].should == v
        end
    end

    describe '#[]' do
        it 'should retrieve an object by key' do
            v = 'val2'
            @cache[:key] = v
            @cache[:key].should == v
            @cache.empty?.should be_false
        end

        context 'when the key does not exist' do
            it 'should return nil' do
                @cache[:some_key].should be_nil
            end
        end
    end

    describe '#fetch_or_store' do
        context 'when the passed key exists' do
            it 'should return its value' do
                old_val = 'my val'
                new_val = 'new val'

                cache = Arachni::Cache::Base.new
                cache[:my_key] = old_val
                cache.fetch_or_store( :my_key ) { new_val }

                cache[:my_key].should == old_val
            end
        end

        context 'when the passed key does not exist' do
            it 'should assign to it the return value of the block return that value' do
                new_val = 'new val'
                cache = Arachni::Cache::Base.new
                cache.fetch_or_store( :my_key ) { new_val }

                cache[:my_key].should == new_val
            end
        end
    end

    describe '#include?' do
        context 'when the key exists' do
            it 'should return true' do
                @cache[:key1] = 'v'
                @cache.include?( :key1 ).should be_true
            end
        end
        context 'when the key does not exist' do
            it 'should return false' do
                @cache.include?( :key2 ).should be_false
            end
        end
    end

    describe '#delete' do
        context 'when the key exists' do
            it 'should delete a key and return its value' do
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
            it 'should return true' do
                @cache.empty?.should be_true
            end
        end
        context 'when cache is not empty' do
            it 'should return false' do
                @cache['ee'] = 'rr'
                @cache.empty?.should be_false
            end
        end
    end

    describe '#any?' do
        context 'when cache is empty' do
            it 'should return false' do
                @cache.any?.should be_false
            end
        end
        context 'when cache is not empty' do
            it 'should return true' do
                @cache['ee'] = 'rr'
                @cache.any?.should be_true
            end
        end
    end

    describe '#clear' do
        it 'should empty the cache' do
            @cache[:my_key2] = 'v'
            @cache.size.should > 0
            @cache.empty?.should be_false
            @cache.clear

            @cache.size.should == 0
            @cache.empty?.should be_true
        end
    end

end
