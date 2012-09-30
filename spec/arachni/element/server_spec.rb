require_relative '../../spec_helper'

describe Arachni::Element::SERVER do
    describe 'Arachni::Element::SERVER' do
        it 'should return "server"' do
            Arachni::Element::SERVER.should == 'server'
        end
    end
end
