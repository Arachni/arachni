require 'spec_helper'

describe Arachni::State::HTTP do
    after(:each) do
        FileUtils.rm_rf @dump_directory if @dump_directory
    end

    subject { described_class.new }
    let(:cookie) { Factory[:cookie] }
    let(:dump_directory) do
        @dump_directory = "#{Dir.tmpdir}/http-#{Arachni::Utilities.generate_token}"
    end

    describe '#headers' do
        it 'returns a Hash' do
            subject.headers.should be_kind_of Hash
        end
    end

    describe '#cookiejar' do
        it "returns a #{Arachni::HTTP::CookieJar}" do
            subject.cookiejar.should be_kind_of Arachni::HTTP::CookieJar
        end
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        it 'includes :cookies' do
            subject.cookiejar << cookie
            statistics[:cookies].should == [cookie.to_s]
        end
    end

    describe '#dump' do
        it 'stores to disk' do
            subject.headers['X-Stuff'] = 'my stuff'
            subject.dump( dump_directory )
        end
    end

    describe '.load' do
        it 'restores from disk' do
            subject.headers['X-Stuff'] = 'my stuff'
            subject.cookiejar << cookie
            subject.dump( dump_directory )

            http = described_class.load( dump_directory )
            http.headers.should == subject.headers
            http.cookiejar.should == subject.cookiejar
        end
    end

    describe '#clear' do
        it 'clears the list' do
            subject.headers.should receive(:clear)
            subject.cookiejar.should receive(:clear)

            subject.clear
        end
    end

end
