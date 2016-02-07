require 'spec_helper'

describe Arachni::Support::Glob do

    let(:conversions) do
        {
            '*'      => /^.*?$/i,
            'test*'  => /^test.*?$/i,
            '*test*' => /^.*?test.*?$/i,
            '*/*'    => /^.*?\/.*?$/i
        }
    end

    let(:matches) do
        [
            ['*',       '',                 true],
            ['*',       'stuff',            true],

            ['test*',   'stuff',            false],
            ['test*',   'teststuff',        true],
            ['test*',   'tEsTstuff',        true],
            ['test*',   'stuffteststuff',   false],

            ['*test*',  'stuffteststuff',   true],
            ['*test*',  'stufftEsTstuff',   true],
            ['*test*',  'stuff',            false],
            ['*test*',  'teststuff',        true],
            ['*test*',  'stufftest',        true],

            ['*/*',     'test',             false],
            ['*/*',     'test/',            true],
            ['*/*',     'test/stuff',       true]
        ]
    end

    describe '.to_regexp' do
        it 'converts a glog to a regexp' do
            conversions.each do |glob, regexp|
                expect(described_class.to_regexp( glob )).to eq regexp
            end
        end
    end

    describe '#regexp' do
        it 'returns the glob as a regexp' do
            conversions.each do |glob, regexp|
                expect(described_class.new( glob ).regexp).to eq regexp
            end
        end
    end

    describe '#match?' do
        it 'checks whether or not the glob matches the string' do
            matches.each do |glob, string, result|
                expect(described_class.new( glob ).match?( string )).to eq result
            end
        end
    end

    describe '#matches?' do
        it 'checks whether or not the glob matches the string' do
            matches.each do |glob, string, result|
                expect(described_class.new( glob ).matches?( string )).to eq result
            end
        end
    end

    describe '=~' do
        it 'checks whether or not the glob matches the string' do
            matches.each do |glob, string, result|
                expect(described_class.new( glob ) =~ string ).to eq result
            end
        end
    end
end
