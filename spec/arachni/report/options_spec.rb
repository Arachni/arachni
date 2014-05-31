require 'spec_helper'

class Subject
    include Arachni::Report::Options
end

describe Arachni::Report::Options do
    subject { Subject.new }

    describe '#outfile' do
        it 'returns an :outfile report option' do
            subject.outfile.name.should == :outfile
        end

        it 'has a default value' do
            subject.outfile.default.should be_true
        end

        context 'when given an extension' do
            it 'appends it to the default filename' do
                extension = '.stuff'
                subject.outfile( extension ).effective_value.end_with?( extension )
            end
        end

        context 'when given a description' do
            it 'assigns it to the option' do
                description = 'My description'
                subject.outfile( '', description ).description.should == description
            end
        end
    end

    describe '#skip_responses' do
        it 'returns a :skip_responses report option' do
            subject.skip_responses.name.should == :skip_responses
        end

        it "defaults to 'false'" do
            subject.skip_responses.default.should == false
        end

        it 'has a description' do
            subject.skip_responses.description.should be_true
        end
    end

end
