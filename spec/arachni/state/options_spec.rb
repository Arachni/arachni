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

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        it 'includes :url' do
            Arachni::Options.url = 'http://test/'
            statistics[:url].should == Arachni::Options.url
        end

        it 'includes :checks' do
            Arachni::Options.checks = %w(xss* sql_injection)
            statistics[:checks].should == Arachni::Options.checks
        end

        it 'includes :plugins' do
            Arachni::Options.plugins = { 'autologin' => {} }
            statistics[:plugins].should == %w(autologin)
        end
    end

    describe '#dump' do
        it 'stores to disk' do
            Arachni::Options.datastore.my_custom_option = 'my value'
            subject.dump( dump_directory )

            Arachni::Options.load( "#{dump_directory}/options" ).
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
