require 'spec_helper'

class MyArr < Array
    attr_accessor :stuff
end

describe Enumerable do

    before( :all ) do
        @v = []
        @v << 'string'
        @v << 'str'
        @v << 'str'
        @v << :k
        @v << 'my value'
    end

    describe '#realsize' do
        it 'returns the sum of the real size of its elements' do
            c = @v.dup
            v = @v.dup

            a = [ v.pop, [ v.pop, [ v.pop, { v.pop => v.pop } ] ] ]
            a.realsize.should == c.reduce(0) { |s, i| s += i.size }
        end

        context 'when the instance has variables' do
            it 'adds their size to the sum' do
                ma = MyArr.new( @v )
                ma.stuff = 'my stuff'

                ma.realsize.should > @v.realsize
            end
        end
    end

end
