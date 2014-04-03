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
                subject.send(type).should be_kind_of Arachni::Support::LookUp::HashSet
            end
        end
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        %w(forms links cookies).each do |type|
            it "includes the amount of seen :#{type}" do
                subject.send(type) << type
                statistics[type.to_sym].should == subject.send(type).size
            end
        end
    end

    describe '#dump' do
        it 'stores to disk' do
            subject.forms << 'form'
            subject.links << 'link'
            subject.cookies << 'cookie'

            subject.dump( dump_directory )

            File.exist?( "#{dump_directory}/sets" ).should be_true
        end
    end

    describe '.load' do
        it 'restores from disk' do
            subject.forms << 'form'
            subject.links << 'link'
            subject.cookies << 'cookie'

            subject.dump( dump_directory )

            subject.should == described_class.load( dump_directory )
        end
    end

    describe '#clear' do
        %w(forms links cookies).each do |type|
            it "clears ##{type}" do
                subject.send(type) << 'stuff'
                subject.send(type).should_not be_empty
                subject.clear
                subject.send(type).should be_empty
            end
        end
    end
end
