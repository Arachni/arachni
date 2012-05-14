require_relative '../../../spec_helper'

describe Arachni::Component::Options::Port do
    before( :all ) do
        @opt = Arachni::Component::Options::Port.new( '' )
    end

    describe '#valid?' do
        context 'when the path exists' do
            it 'should return true' do
                (1..65535).each do |p|
                    @opt.valid?( p ).should be_true
                    @opt.valid?( p.to_s ).should be_true
                end
            end
        end
        context 'when the path does not exist' do
            it 'should return false' do
                @opt.valid?( 'dd' ).should be_false
                @opt.valid?( -1 ).should be_false
                @opt.valid?( 0 ).should be_false
                @opt.valid?( 999999 ).should be_false
            end
        end
        context 'when required but empty' do
            it 'should return false' do
                @opt.class.new( '', [true] ).valid?( nil ).should be_false
            end
        end
    end

    describe '#type' do
        it 'should return the option type as a string' do
            @opt.type.should == 'port'
        end
    end

end
