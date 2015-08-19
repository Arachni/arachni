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

            expect(b).to eq([ [1,2] ])
        end
    end

end
