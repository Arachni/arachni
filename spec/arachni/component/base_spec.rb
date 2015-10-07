require 'spec_helper'

class Subject < Arachni::Component::Base

    def self.info
        {
            name:        'My full name',
            description: 'My description',
            author:      'My author',
            version:     'My version'
        }
    end

end

describe Arachni::Component::Base do
    subject { Subject }
    let(:info) { Subject.info }

    it "includes #{Arachni::Component::Output}" do
        expect(subject).to include Arachni::Component::Output
    end

    it "includes #{Arachni::Component::Utilities}" do
        expect(subject).to include Arachni::Component::Utilities
    end

    describe '.shortname=' do
        it 'sets the .shortname' do
            subject.shortname = :blah
            expect(subject.shortname).to eq(:blah)
        end

        it 'sets the #shortname' do
            subject.shortname = :blah
            expect(subject.new.shortname).to eq(:blah)
        end
    end

    describe '.fullname' do
        it 'returns the name' do
            expect(subject.fullname).to eq(info[:name])
        end
    end

    describe '.description' do
        it 'returns the description' do
            expect(subject.description).to eq(info[:description])
        end
    end

    describe '.author' do
        it 'returns the author' do
            expect(subject.author).to eq(info[:author])
        end
    end

    describe '.version' do
        it 'returns the version' do
            expect(subject.version).to eq(info[:version])
        end
    end

end
