require_relative '../../spec_helper'

class ObservableTest
    include Arachni::Mixins::Observable

    def a_method( *args )
        call_a_method( *args )
    end
end

describe Arachni::Mixins::Observable do

    before :all do
        @obs = ObservableTest.new
    end

    it 'should call single hook without args' do
        res = false
        @obs.add_a_method { res = true }
        @obs.a_method
        res.should == true
    end

    it 'should call multiple hooks without args' do
        res1 = false
        res2 = false
        @obs.add_a_method { res1 = true }
        @obs.on_a_method { res2 = true }
        @obs.a_method
        res1.should == true
        res2.should == true
    end

    it 'should call single hook with args' do
        res = false
        @obs.add_a_method { |param| res = param }
        @obs.a_method( true )
        res.should == true
    end

    it 'should call multiple hooks with args' do
        res1 = false
        res2 = false
        @obs.add_a_method { |param| res1 = param }
        @obs.on_a_method { |param| res2 = param }
        @obs.a_method( true )
        res1.should == true
        res2.should == true
    end

    it 'should raise NoMethodError on invalid method name' do
        begin
            @obs.blah
        rescue Exception => e
            e.class.should == NoMethodError
        end
    end

end
