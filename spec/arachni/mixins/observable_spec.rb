require 'spec_helper'

class ObservableTest
    include Arachni::Mixins::Observable

    def hooks
        @__hooks
    end

    def a_method( *args )
        call_a_method( *args )
    end
end

describe Arachni::Mixins::Observable do

    before :all do
        @obs = ObservableTest.new
    end

    before( :each ) { @obs.clear_observers }

    it 'calls a single hook without args' do
        res = false
        @obs.add_a_method { res = true }
        @obs.a_method
        res.should == true
    end

    it 'calls multiple hooks without args' do
        res1 = false
        res2 = false
        @obs.add_a_method { res1 = true }
        @obs.on_a_method { res2 = true }
        @obs.a_method
        res1.should == true
        res2.should == true
    end

    it 'call a single hook with args' do
        res = false
        @obs.add_a_method { |param| res = param }
        @obs.a_method( true )
        res.should == true
    end

    it 'calls multiple hooks with args' do
        res1 = false
        res2 = false
        @obs.add_a_method { |param| res1 = param }
        @obs.on_a_method { |param| res2 = param }
        @obs.a_method( true )
        res1.should == true
        res2.should == true
    end

    context 'on invalid method name' do
        it 'raises NoMethodError' do
            expect { @obs.blah }.to raise_error NoMethodError
        end
    end

    describe 'clear_observers' do
        it 'clears all callbacks' do
            @obs.hooks.should be_empty

            @obs.on_a_method {}
            @obs.hooks.should be_any

            @obs.clear_observers
            @obs.hooks.should be_empty
        end
    end

end
