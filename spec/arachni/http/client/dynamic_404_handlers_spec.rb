require 'spec_helper'

describe Arachni::HTTP::Client::Dynamic404Handler do

    before( :all ) do
        @url = web_server_url_for( :dynamic_404_handler )
    end
    after do
        Arachni::HTTP::Client.reset
    end

    subject { client.dynamic_404_handler }
    let(:client) { Arachni::HTTP::Client }
    let(:url) { "#{@url}/" }

    describe '#_404?' do
        context 'when not dealing with a not-found response' do
            it 'returns false' do
                res = nil
                client.get( url + 'not' ) { |c_res| res = c_res }
                client.run
                bool = false
                subject._404?( res ) { |c_bool| bool = c_bool }
                client.run
                bool.should be_false
            end
        end

        context 'when dealing with a static handler' do
            it 'returns true' do
                res = nil
                client.get( url + 'static/crap' ) { |c_res| res = c_res }
                client.run
                bool = false
                subject._404?( res ) { |c_bool| bool = c_bool }
                client.run
                bool.should be_true
            end
        end

        context 'when dealing with a dynamic handler' do
            context 'which includes the requested resource in the response' do
                it 'returns true' do
                    res = nil
                    client.get( url + 'dynamic/crap' ) { |c_res| res = c_res }
                    client.run
                    bool = false
                    subject._404?( res ) { |c_bool| bool = c_bool }
                    client.run
                    bool.should be_true
                end
            end
            context 'which includes constantly changing text in the response' do
                it 'returns true' do
                    res = nil
                    client.get( url + 'random/crap' ) { |c_res| res = c_res }
                    client.run
                    bool = false
                    subject._404?( res ) { |c_bool| bool = c_bool }
                    client.run
                    bool.should be_true
                end
            end
            context 'which returns a combination of the above' do
                it 'returns true' do
                    res = nil
                    client.get( url + 'combo/crap' ) { |c_res| res = c_res }
                    client.run
                    bool = false
                    subject._404?( res ) { |c_bool| bool = c_bool }
                    client.run
                    bool.should be_true
                end
            end

            context 'when checking for a resource with a name and extension' do
                context 'and the handler is extension-sensitive' do
                    it 'returns true' do
                        res = nil
                        client.get( url + 'advanced/sensitive-ext/blah.html2' ) { |c_res| res = c_res }
                        client.run

                        bool = false
                        subject._404?( res ) { |c_bool| bool = c_bool }
                        client.run

                        bool.should be_true
                    end
                end
            end
        end

        context 'when checking for an already checked URL' do
            it 'returns the cached result' do
                res = nil
                client.get( url + 'static/crap' ) { |c_res| res = c_res }
                client.run

                bool = false
                subject._404?( res ) { |c_bool| bool = c_bool }
                client.run
                bool.should be_true

                fingerprints = 0
                client.on_complete do
                    fingerprints += 1
                end

                res = nil
                client.get( url + 'static/crap' ) { |c_res| res = c_res }
                client.run
                fingerprints.should > 0

                overhead = 0
                client.on_complete do
                    overhead += 1
                end

                bool = false
                subject._404?( res ) { |c_bool| bool = c_bool }
                client.run
                bool.should be_true

                overhead.should == 0
            end
        end

        context "when the signature cache exceeds #{described_class::CACHE_SIZE} entries" do
            it 'it is pruned as soon as possible' do
                subject.signatures.should be_empty

                (2 * described_class::CACHE_SIZE).times do |i|
                    client.get( url + "static/#{i}/test" ) do |response|
                        subject._404?( response ) {}
                    end
                end
                client.run

                subject.signatures.size.should == described_class::CACHE_SIZE
            end
        end
    end

    describe '#checked_and_static?' do
        let(:url) { super() + 'combo/crap' }
        let(:path) { client.get_path( url ) }

        context 'when the page has been fingerprinted' do
            context 'and it has a custom handler' do
                it 'returns false' do
                    client.get( url ) do |response|
                        subject._404?( response ) {}
                    end
                    client.run

                    subject.checked_and_static?( path ).should be_false
                end
            end

            context 'and it does not have a custom handler' do
                it 'returns true' do
                    client.get( @url ) do |response|
                        subject._404?( response ) {}
                    end
                    client.run

                    subject.checked_and_static?( client.get_path( @url ) ).should be_true
                end
            end
        end

        context 'when the page has not been fingerprinted' do
            it 'returns false' do
                subject.checked_and_static?( path ).should be_false
            end
        end
    end

    describe '#checked?' do
        let(:url) { super() + 'combo/crap' }

        context 'when the page has been fingerprinted' do
            context 'and it has a dynamic handler' do
                it 'returns true' do
                    client.get( url ) do |response|
                        subject._404?( response ) {}
                    end
                    client.run

                    subject.checked?( url ).should be_true
                end
            end

            context 'and it has a static handler' do
                it 'returns true' do
                    client.get( @url ) do |response|
                        subject._404?( response ) {}
                    end
                    client.run

                    subject.checked?( @url ).should be_true
                end
            end
        end

        context 'when the page has not been fingerprinted' do
            it 'returns false' do
                subject.checked?( url ).should be_false
            end
        end
    end

    describe 'needs_check?' do
        context 'when #checked?' do
            context false do
                before(:each) { subject.stub(:checked?) { false } }

                it 'returns true' do
                    subject.needs_check?( @url ).should be_true
                end

                context 'and #checked_and_static?' do
                    context false do
                        before(:each) { subject.stub(:checked_and_static?) { false } }

                        it 'returns true' do
                            subject.needs_check?( @url ).should be_true
                        end
                    end

                    context true do
                        before(:each) { subject.stub(:checked_and_static?) { true } }

                        it 'returns true' do
                            subject.needs_check?( @url ).should be_true
                        end
                    end
                end
            end

            context true do
                before(:each) { subject.stub(:checked?) { true } }

                it 'returns true' do
                    subject.needs_check?( @url ).should be_true
                end

                context 'and #checked_and_static?' do
                    context true do
                        before(:each) { subject.stub(:checked_and_static?) { true } }

                        it 'returns false' do
                            subject.needs_check?( @url ).should be_false
                        end
                    end

                    context false do
                        before(:each) { subject.stub(:checked_and_static?) { false } }

                        it 'returns true' do
                            subject.needs_check?( @url ).should be_true
                        end
                    end
                end
            end
        end
    end

    describe '.info' do
        it 'returns a hash with an output name' do
            described_class.info[:name].should == 'Dynamic404Handler'
        end
    end
end
