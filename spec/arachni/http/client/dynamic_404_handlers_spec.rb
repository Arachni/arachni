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
        context 'when not dealing with a redirect' do
            context 'to an outside custom 404' do
                it 'returns true' do
                    @dynamic_404_handler_redirect_1 =
                        web_server_url_for( :dynamic_404_handler_redirect_1 )

                    @dynamic_404_handler_redirect_2 =
                        web_server_url_for( :dynamic_404_handler_redirect_2 )

                    Arachni::HTTP::Client.get(
                        "#{@dynamic_404_handler_redirect_1}/set-redirect",
                        parameters: {
                            url: @dynamic_404_handler_redirect_2
                        },
                        mode: :sync
                    )

                    response = client.get(
                        @dynamic_404_handler_redirect_1 + '/test/stuff.php',
                        follow_location: true,
                        mode:            :sync
                    )

                    bool = false
                    subject._404?( response ) { |c_bool| bool = c_bool }
                    client.run

                    expect(bool).to be_true
                end
            end
        end

        context 'when not dealing with a not-found response' do
            it 'returns false' do
                res = nil
                client.get( url + 'not' ) { |c_res| res = c_res }
                client.run
                bool = false
                subject._404?( res ) { |c_bool| bool = c_bool }
                client.run
                expect(bool).to be_falsey
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
                expect(bool).to be_truthy
            end
        end

        context 'when dealing with a dynamic handler' do
            context 'which at any point returns non-200' do
                it 'aborts the check' do
                    response = client.get( url + 'dynamic/erratic/code/test', mode: :sync )

                    check = nil
                    subject._404?( response ) { |bool| check = bool }
                    client.run

                    expect(check).to be_nil
                end
            end

            context 'which is too erratic' do
                it 'aborts the check' do
                    response = client.get( url + 'dynamic/erratic/body/test', mode: :sync )

                    check = nil
                    subject._404?( response ) { |bool| check = bool }
                    client.run

                    expect(check).to be_nil
                end
            end

            context 'which includes the requested resource in the response' do
                it 'returns true' do
                    res = nil
                    client.get( url + 'dynamic/crap' ) { |c_res| res = c_res }
                    client.run
                    bool = nil
                    subject._404?( res ) { |c_bool| bool = c_bool }
                    client.run
                    expect(bool).to be_truthy
                end
            end

            context 'which includes constantly changing text in the response' do
                it 'returns true' do
                    res = nil
                    client.get( url + 'random/crap' ) { |c_res| res = c_res }
                    client.run
                    bool = nil
                    subject._404?( res ) { |c_bool| bool = c_bool }
                    client.run
                    expect(bool).to be_truthy
                end
            end
            context 'which returns a combination of the above' do
                it 'returns true' do
                    res = nil
                    client.get( url + 'combo/crap' ) { |c_res| res = c_res }
                    client.run
                    bool = nil
                    subject._404?( res ) { |c_bool| bool = c_bool }
                    client.run
                    expect(bool).to be_truthy
                end
            end

            context 'when checking for a resource with a name and extension' do
                context 'and the handler is extension-sensitive' do
                    it 'returns true' do
                        res = nil
                        client.get( url + 'advanced/sensitive-ext/blah.html2' ) { |c_res| res = c_res }
                        client.run

                        bool = nil
                        subject._404?( res ) { |c_bool| bool = c_bool }
                        client.run

                        expect(bool).to be_truthy
                    end
                end
            end

            context 'when checking for a resource with a name that includes ~' do
                context 'and the handler ignores it' do
                    it 'returns true'
                end
            end

            context 'which ignores anything past the resource name' do
                context 'with a non existent resource' do
                    it 'returns true' do
                        res = nil
                        client.get( url + '/ignore-after-filename/123dd/' ) { |c_res| res = c_res }
                        client.run

                        bool = nil
                        subject._404?( res ) { |c_bool| bool = c_bool }
                        client.run

                        expect(bool).to be_truthy
                    end
                end
            end

            context 'which ignores anything ahead of the resource name' do
                context 'with a non existent resource' do
                    it 'returns true' do
                        res = nil
                        client.get( url + '/ignore-before-filename/fff123/' ) { |c_res| res = c_res }
                        client.run

                        bool = nil
                        subject._404?( res ) { |c_bool| bool = c_bool }
                        client.run

                        expect(bool).to be_truthy
                    end
                end
            end

            context 'when checking for a resource with a name that routes based on dash' do
                context 'and the handler is pre-dash sensitive' do
                    context 'and is found' do
                        it 'returns false' do
                            res = nil
                            client.get( url + 'advanced/sensitive-dash/pre/blah-html' ) { |c_res| res = c_res }
                            client.run

                            bool = nil
                            subject._404?( res ) { |c_bool| bool = c_bool }
                            client.run

                            expect(bool).to be_falsey
                        end
                    end

                    context 'and is not found' do
                        it 'returns true' do
                            res = nil
                            client.get( url + 'advanced/sensitive-dash/pre/blah2-html' ) { |c_res| res = c_res }
                            client.run

                            bool = nil
                            subject._404?( res ) { |c_bool| bool = c_bool }
                            client.run

                            expect(bool).to be_truthy
                        end
                    end
                end

                context 'and the handler is post-dash sensitive' do
                    context 'and is found' do
                        it 'returns false' do
                            res = nil
                            client.get( url + 'advanced/sensitive-dash/post/blah-html' ) { |c_res| res = c_res }
                            client.run

                            bool = nil
                            subject._404?( res ) { |c_bool| bool = c_bool }
                            client.run

                            expect(bool).to be_falsey
                        end
                    end

                    context 'and is not found' do
                        it 'returns true' do
                            res = nil
                            client.get( url + 'advanced/sensitive-dash/post/blah-html2' ) { |c_res| res = c_res }
                            client.run

                            bool = nil
                            subject._404?( res ) { |c_bool| bool = c_bool }
                            client.run

                            expect(bool).to be_truthy
                        end
                    end
                end
            end
        end

        context 'when checking for an already checked URL' do
            it 'returns the cached result' do
                res = nil
                client.get( url + 'static/crap' ) { |c_res| res = c_res }
                client.run

                bool = nil
                subject._404?( res ) { |c_bool| bool = c_bool }
                client.run
                expect(bool).to be_truthy

                fingerprints = 0
                client.on_complete do
                    fingerprints += 1
                end

                res = nil
                client.get( url + 'static/crap' ) { |c_res| res = c_res }
                client.run
                expect(fingerprints).to be > 0

                overhead = 0
                client.on_complete do
                    overhead += 1
                end

                bool = nil
                subject._404?( res ) { |c_bool| bool = c_bool }
                client.run
                expect(bool).to be_truthy

                expect(overhead).to eq(0)
            end
        end

        context "when the signature cache exceeds #{described_class::CACHE_SIZE} entries" do
            it 'it is pruned as soon as possible' do
                expect(subject.signatures).to be_empty

                (2 * described_class::CACHE_SIZE).times do |i|
                    client.get( url + "static/#{i}/test" ) do |response|
                        subject._404?( response ) {}
                    end
                end
                client.run

                expect(subject.signatures.size).to eq(described_class::CACHE_SIZE)
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

                    expect(subject.checked_and_static?( path )).to be_falsey
                end
            end

            context 'and it does not have a custom handler' do
                it 'returns true' do
                    client.get( @url ) do |response|
                        subject._404?( response ) {}
                    end
                    client.run

                    expect(subject.checked_and_static?( client.get_path( @url ) )).to be_truthy
                end
            end
        end

        context 'when the page has not been fingerprinted' do
            it 'returns false' do
                expect(subject.checked_and_static?( path )).to be_falsey
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

                    expect(subject.checked?( url )).to be_truthy
                end
            end

            context 'and it has a static handler' do
                it 'returns true' do
                    client.get( @url ) do |response|
                        subject._404?( response ) {}
                    end
                    client.run

                    expect(subject.checked?( @url )).to be_truthy
                end
            end
        end

        context 'when the page has not been fingerprinted' do
            it 'returns false' do
                expect(subject.checked?( url )).to be_falsey
            end
        end
    end

    describe 'needs_check?' do
        context 'when #checked?' do
            context 'false' do
                before(:each) { allow(subject).to receive(:checked?) { false } }

                it 'returns true' do
                    expect(subject.needs_check?( @url )).to be_truthy
                end

                context 'and #checked_and_static?' do
                    context 'false' do
                        before(:each) { allow(subject).to receive(:checked_and_static?) { false } }

                        it 'returns true' do
                            expect(subject.needs_check?( @url )).to be_truthy
                        end
                    end

                    context 'true' do
                        before(:each) { allow(subject).to receive(:checked_and_static?) { true } }

                        it 'returns true' do
                            expect(subject.needs_check?( @url )).to be_truthy
                        end
                    end
                end
            end

            context 'true' do
                before(:each) { allow(subject).to receive(:checked?) { true } }

                it 'returns true' do
                    expect(subject.needs_check?( @url )).to be_truthy
                end

                context 'and #checked_and_static?' do
                    context 'true' do
                        before(:each) { allow(subject).to receive(:checked_and_static?) { true } }

                        it 'returns false' do
                            expect(subject.needs_check?( @url )).to be_falsey
                        end
                    end

                    context 'false' do
                        before(:each) { allow(subject).to receive(:checked_and_static?) { false } }

                        it 'returns true' do
                            expect(subject.needs_check?( @url )).to be_truthy
                        end
                    end
                end
            end
        end
    end

    describe '.info' do
        it 'returns a hash with an output name' do
            expect(described_class.info[:name]).to eq('Dynamic404Handler')
        end
    end
end
