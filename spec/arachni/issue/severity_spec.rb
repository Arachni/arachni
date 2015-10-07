require 'spec_helper'

describe Arachni::Issue::Severity do
    describe 'Arachni::Issue::Severity::HIGH' do
        it 'returns "high"' do
            expect(Arachni::Issue::Severity::HIGH.to_s).to eq('high')
        end
    end
    describe 'Arachni::Issue::Severity::MEDIUM' do
        it 'returns "medium"' do
            expect(Arachni::Issue::Severity::MEDIUM.to_s).to eq('medium')
        end
    end
    describe 'Arachni::Issue::Severity::LOW' do
        it 'returns "low"' do
            expect(Arachni::Issue::Severity::LOW.to_s).to eq('low')
        end
    end
    describe 'Arachni::Issue::Severity::INFORMATIONAL' do
        it 'returns "informational"' do
            expect(Arachni::Issue::Severity::INFORMATIONAL.to_s).to eq('informational')
        end
    end

    it 'is assigned to Arachni::Severity for easy access' do
        expect(Arachni::Severity).to eq(Arachni::Issue::Severity)
    end

    it 'is comparable' do
        informational = Arachni::Issue::Severity::INFORMATIONAL
        low           = Arachni::Issue::Severity::LOW
        medium        = Arachni::Issue::Severity::MEDIUM
        high          = Arachni::Issue::Severity::HIGH

        expect(informational).to be < low
        expect(low).to be < medium
        expect(medium).to be < high

        expect([low, informational, high, medium].sort).to eq(
            [informational, low, medium, high]
        )
    end

end
