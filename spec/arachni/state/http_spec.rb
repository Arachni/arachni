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
            expect(subject.headers).to be_kind_of Hash
        end
    end

    describe '#cookie_jar' do
        it "returns a #{Arachni::HTTP::CookieJar}" do
            expect(subject.cookie_jar).to be_kind_of Arachni::HTTP::CookieJar
        end
    end

    describe '#statistics' do
        let(:statistics) { subject.statistics }

        it 'includes :cookies' do
            subject.cookie_jar << cookie
            expect(statistics[:cookies]).to eq([cookie.to_s])
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
            subject.cookie_jar << cookie
            subject.dump( dump_directory )

            http = described_class.load( dump_directory )
            expect(http.headers).to eq(subject.headers)
            expect(http.cookie_jar).to eq(subject.cookie_jar)
        end
    end

    describe '#clear' do
        it 'clears the list' do
            expect(subject.headers).to receive(:clear)
            expect(subject.cookie_jar).to receive(:clear)

            subject.clear
        end
    end

end
