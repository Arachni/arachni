require 'spec_helper'

describe Arachni::State::Options do
    after(:each) do
        FileUtils.rm_rf @dump_directory if @dump_directory
    end

    subject { described_class.new }
    let(:dump_directory) do
        @dump_directory = "#{Dir.tmpdir}/options-#{Arachni::Utilities.generate_token}"
    end

    it { should respond_to :clear}

    describe '#dump' do
        it 'stores to disk' do
            Arachni::Options.datastore.my_custom_option = 'my value'
            subject.dump( dump_directory )

            Arachni::Options.load( "#{dump_directory}/options.afr" ).
                datastore.my_custom_option.should == 'my value'
        end
    end

    describe '.load' do
        it 'restores from disk' do
            Arachni::Options.datastore.my_custom_option = 'my value'
            subject.dump( dump_directory )

            described_class.load( dump_directory )

            Arachni::Options.datastore.my_custom_option.should == 'my value'
        end
    end

end
