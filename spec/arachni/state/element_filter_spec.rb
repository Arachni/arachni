require 'spec_helper'

describe Arachni::State::ElementFilter do
    after(:each) do
        FileUtils.rm_rf @dump_directory if @dump_directory
    end

    subject { described_class.new }
    let(:dump_directory) do
        @dump_directory = "#{Dir.tmpdir}/element-filter-#{Arachni::Utilities.generate_token}"
    end

    %w(forms links cookies).each do |type|
        describe "##{type}" do
            it "returns a #{Arachni::Support::LookUp::HashSet}" do
                expect(subject.send(type)).to be_kind_of Arachni::Support::LookUp::HashSet
            end
        end
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        %w(forms links cookies).each do |type|
            it "includes the amount of seen :#{type}" do
                subject.send(type) << type
                expect(statistics[type.to_sym]).to eq(subject.send(type).size)
            end
        end
    end

    describe '#dump' do
        it 'stores to disk' do
            subject.forms << 'form'
            subject.links << 'link'
            subject.cookies << 'cookie'

            subject.dump( dump_directory )

            expect(File.exist?( "#{dump_directory}/sets" )).to be_truthy
        end
    end

    describe '.load' do
        it 'restores from disk' do
            subject.forms << 'form'
            subject.links << 'link'
            subject.cookies << 'cookie'

            subject.dump( dump_directory )

            expect(subject).to eq(described_class.load( dump_directory ))
        end
    end

    describe '#clear' do
        %w(forms links cookies).each do |type|
            it "clears ##{type}" do
                subject.send(type) << 'stuff'
                expect(subject.send(type)).not_to be_empty
                subject.clear
                expect(subject.send(type)).to be_empty
            end
        end
    end
end
