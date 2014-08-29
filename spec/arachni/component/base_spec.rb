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
        subject.should include Arachni::Component::Output
    end

    it "includes #{Arachni::Component::Utilities}" do
        subject.should include Arachni::Component::Utilities
    end

    describe '.shortname=' do
        it 'sets the .shortname' do
            subject.shortname = :blah
            subject.shortname.should == :blah
        end

        it 'sets the #shortname' do
            subject.shortname = :blah
            subject.new.shortname.should == :blah
        end
    end

    describe '.fullname' do
        it 'returns the name' do
            subject.fullname.should == info[:name]
        end
    end

    describe '.description' do
        it 'returns the description' do
            subject.description.should == info[:description]
        end
    end

    describe '.author' do
        it 'returns the author' do
            subject.author.should == info[:author]
        end
    end

    describe '.version' do
        it 'returns the version' do
            subject.version.should == info[:version]
        end
    end

end
