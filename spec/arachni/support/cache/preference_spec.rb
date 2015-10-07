require 'spec_helper'

describe Arachni::Support::Cache::Preference do
    it_behaves_like 'cache'

    it 'prunes itself by removing entries returned by the given block' do
        subject.max_size = 3

        subject.prefer { :k2 }

        k = [ :k, :k2, :k3, :k4 ]
        subject[k[0]] = '1'
        subject[k[1]] = '2'
        subject[k[2]] = '3'
        subject[k[3]] = '4'
        expect(subject.size).to eq(3)

        expect(k.map { |key| subject[key] }.count( nil )).to eq(1)

        subject.clear
    end

    it 'does not remove entries which are not preferred even if the max size has been exceeded' do
        subject.prefer { :k2 }

        k = [ :k, :k2, :k3, :k4 ]

        subject.max_size = 1
        subject[k[0]]  = '1'
        subject[k[1]] = '3'
        subject[k[2]] = '4'
        expect(subject.size).to eq(2)

        expect(k[0...3].map { |key| subject[key] }.count( nil )).to eq(1)
    end

end
