require 'spec_helper'

class Empty
end

class MyClass
    attr_accessor :stuff
end

describe Object do

    describe '#deep_clone' do
        it 'returns a deep copy of the object' do
            a = [ [1,2] ]
            b = a.deep_clone
            a[0] << 3

            b.should == [ [1,2] ]
        end
    end

    describe '#realsize' do
        context 'when the class has instance variables' do
            it 'returns an integer > 0' do
                s = MyClass.new
                s.stuff = 'my stuff'
                s.realsize.should > 0
            end
        end
        context 'when the class has instance variables' do
            it 'returns nil' do
                s = Empty.new
                s.realsize.should == 0
            end
        end
    end

end
