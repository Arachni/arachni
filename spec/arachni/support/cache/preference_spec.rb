require 'spec_helper'

describe Arachni::Support::Cache::Preference do

    before { @cache = described_class.new }

    it 'prunes itself by removing entries returned by the given block' do
        @cache.max_size = 3

        @cache.prefer { :k2 }

        k = [ :k, :k2, :k3, :k4 ]
        @cache[k[0]] = '1'
        @cache[k[1]] = '2'
        @cache[k[2]] = '3'
        @cache[k[3]] = '4'
        @cache.size.should == 3

        k.map { |key| @cache[key] }.count( nil ).should == 1

        @cache.clear
    end

    it 'does not remove entries which are not preferred even if the max size has been exceeded' do
        @cache.prefer { :k2 }

        k = [ :k, :k2, :k3, :k4 ]

        @cache.max_size = 1
        @cache[k[0]]  = '1'
        @cache[k[1]] = '3'
        @cache[k[2]] = '4'
        @cache.size.should == 2

        k[0...3].map { |key| @cache[key] }.count( nil ).should == 1
    end

end
