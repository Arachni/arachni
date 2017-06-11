require 'spec_helper'

class Subject
    include Arachni::Reporter::Options
end

describe Arachni::Reporter::Options do
    subject { Subject.new }

    describe '#outfile' do
        it 'returns an :outfile reporter option' do
            expect(subject.outfile.name).to eq(:outfile)
        end

        it 'has a default value' do
            expect(subject.outfile.default).to be_truthy
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
                expect(subject.outfile( '', description ).description).to eq(description)
            end
        end
    end

end
