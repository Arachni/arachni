require 'spec_helper'

describe Arachni::Issue::Severity do
    describe 'Arachni::Issue::Severity::HIGH' do
        it 'returns "high"' do
            Arachni::Issue::Severity::HIGH.to_s.should == 'high'
        end
    end
    describe 'Arachni::Issue::Severity::MEDIUM' do
        it 'returns "medium"' do
            Arachni::Issue::Severity::MEDIUM.to_s.should == 'medium'
        end
    end
    describe 'Arachni::Issue::Severity::LOW' do
        it 'returns "low"' do
            Arachni::Issue::Severity::LOW.to_s.should == 'low'
        end
    end
    describe 'Arachni::Issue::Severity::INFORMATIONAL' do
        it 'returns "informational"' do
            Arachni::Issue::Severity::INFORMATIONAL.to_s.should == 'informational'
        end
    end

    it 'is assigned to Arachni::Severity for easy access' do
        Arachni::Severity.should == Arachni::Issue::Severity
    end

    it 'is comparable' do
        informational = Arachni::Issue::Severity::INFORMATIONAL
        low           = Arachni::Issue::Severity::LOW
        medium        = Arachni::Issue::Severity::MEDIUM
        high          = Arachni::Issue::Severity::HIGH

        informational.should be < low
        low.should be < medium
        medium.should be < high

        [low, informational, high, medium].sort.should ==
            [informational, low, medium, high]
    end

end
