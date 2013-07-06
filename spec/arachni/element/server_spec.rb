require 'spec_helper'

describe Arachni::Element::SERVER do
    describe 'Arachni::Element::SERVER' do
        it 'returns "server"' do
            Arachni::Element::SERVER.should == 'server'
        end
    end
end
