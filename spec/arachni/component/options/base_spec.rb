require 'spec_helper'

describe Arachni::Component::Options::Base do
    before( :all ) do
        @opt = Arachni::Component::Options::Base
    end

    describe '#name' do
        it 'returns the name of the option' do
            name = 'a name'
            @opt.new( name ).name.should == name
        end
    end

    describe '#desc' do
        it 'returns the description' do
            desc = 'a description'
            @opt.new( '', [ false, desc ] ).desc.should == desc
        end
    end

    describe '#default' do
        it 'returns the default value -- if there is one' do
            default = 'default value'
            @opt.new( '', [ false, '', default ] ).default.should == default
        end
    end

    describe '#enums' do
        it 'returns an array of possible, predefined, values' do
            enums = %w(1 2 3)
            @opt.new( '', [ false, '', nil, enums ] ).enums.should == enums
        end
    end

    describe '#required?' do
        context 'when the option is mandatory' do
            it 'returns true' do
                @opt.new( '', [ true ] ).required?.should be_true
            end
        end

        context 'when the option is not mandatory' do
            it 'returns false' do
                @opt.new( '', [ false ] ).required?.should be_false
            end
        end
    end

    describe '#type?' do
        context 'when the type matches the param' do
            it 'returns true' do
                @opt.new( '' ).type?( 'abstract' ).should be_true
            end
        end
        context 'when the type does not match the param' do
            it 'returns false' do
                @opt.new( '' ).type?( 'blah' ).should be_false
            end
        end
    end

    describe '#valid?' do
        context 'when the value is valid' do
            it 'returns true' do
                @opt.new( '' ).valid?( nil ).should be_true
                @opt.new( '' ).valid?( '' ).should be_true
                @opt.new( '', [ true ] ).valid?( 'blah' ).should be_true
                @opt.new( '' ).valid?( 'blah' ).should be_true
            end
        end
        context 'when the value is not valid' do
            it 'returns false' do
                @opt.new( '', [ true ] ).valid?( nil ).should be_false
                @opt.new( '', [ true ] ).valid?( '' ).should be_false
            end
        end
    end

    describe '#empty_required_value?' do
        context 'when a required value is empty' do
            it 'returns true' do
                @opt.new( '', [ true ] ).empty_required_value?( nil ).should be_true
            end
        end
        context 'when a required value is not empty' do
            it 'returns false' do
                @opt.new( '' ).empty_required_value?( nil ).should be_false
            end
        end
    end

    describe '#normalize' do
        it 'returns the value as is' do
            @opt.new( '' ).normalize( 'blah' ).should == 'blah'
        end
    end

    describe '#type' do
        it 'returns the option type as a string' do
            @opt.new( '' ).type.should == 'abstract'
        end
    end

end
