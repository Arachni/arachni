require 'spec_helper'

describe Arachni::Page::DOM do

    def create_page( options = {} )
        Arachni::Page.new response: Arachni::HTTP::Response.new(
              request: Arachni::HTTP::Request.new(
                           url:    'http://a-url.com/',
                           method: :get,
                           headers: {
                               'req-header-name' => 'req header value'
                           }
                       ),

              code:    200,
              url:     'http://a-url.com/?myvar=my%20value',
              body:    options[:body],
              headers: options[:headers]
          )
    end

    before( :all ) do
        @url = Arachni::Utilities.normalize_url( web_server_url_for( :page_dom ) )
    end

    after( :each ) do
        Arachni::Options.reset
        Arachni::Framework.reset
        @browser.shutdown if @browser
        @browser = nil
    end

    let(:browser) { @browser = Arachni::Browser.new }
    let(:dom) { Factory[:dom] }
    let(:empty_dom) { create_page.dom }
    subject { dom }

    it "supports #{Arachni::RPC::Serializer}" do
        expect(subject).to eq(Arachni::RPC::Serializer.deep_clone( subject ))
    end

    it 'Marshaling ignores the page' do
        expect(subject.page).to be_kind_of Arachni::Page
        dom = Marshal.load( Marshal.dump( subject ) )
        expect(dom.page).to be_nil
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        %w(url digest).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute]).to eq(subject.send( attribute ))
            end
        end

        %w(cookies data_flow_sinks execution_flow_sinks cookies).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute]).to eq(subject.send(attribute).map(&:to_rpc_data))
            end
        end

        it "includes 'skip_states'" do
            expect(data['skip_states']).to eq(subject.skip_states.collection.to_a)
        end
    end

    describe '.from_rpc_data' do
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(url cookies transitions digest skip_states data_flow_sinks
            execution_flow_sinks).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to eq(subject.send( attribute ))
            end
        end
    end

    describe '#url' do
        it 'defaults to the page URL' do
            expect(dom.url).to eq(create_page.url)
        end
    end

    describe '#transitions' do
        it 'defaults to an empty Array' do
            expect(empty_dom.transitions).to eq([])
        end
    end

    describe '#playable_transitions' do
        it 'returns playable transitions' do
            dom.transitions = [
                { :page                              => :load },
                { "http://test.com/"                 => :request },
                { "<body onload='loadStuff();'>"     => :onload },
                { "http://test.com/ajax"             => :request },
                { "<a href='javascript:clickMe();'>" => :click },
            ].map { |t| described_class::Transition.new *t.first }

            expect(dom.playable_transitions).to eq([
                { :page                              => :load },
                { "<body onload='loadStuff();'>"     => :onload },
                { "<a href='javascript:clickMe();'>" => :click },
            ].map { |t| described_class::Transition.new *t.first })
        end
    end

    describe '#data_flow_sinks' do
        it 'defaults to an empty Array' do
            expect(empty_dom.data_flow_sinks).to eq([])
        end
    end

    describe '#data_flow_sinks=' do
        it 'sets #data_flow_sinks' do
            sink = [
                data:  ['stuff'],
                trace: [
                    [
                        function:  "function onClick(some, arguments, here) " <<
                                       "{\n                _16744290dd4cf3a3" <<
                                       "d72033b82f11df32f785b50239268efb173c" <<
                                       "e9ac269714e5.send_to_sink(1);\n     " <<
                                       "           return false;\n            }",
                        arguments: %w(some-arg arguments-arg here-arg)
                    ]
                ]
            ]

            dom.data_flow_sinks = sink
            expect(dom.data_flow_sinks).to eq(sink)
        end
    end

    describe '#execution_flow_sinks' do
        it 'defaults to an empty Array' do
            expect(empty_dom.execution_flow_sinks).to eq([])
        end
    end

    describe '#execution_flow_sinks=' do
        it 'sets #execution_flow_sinks' do
            sink = [
                data:  ['stuff'],
                trace: [
                           [
                               function:  "function onClick(some, arguments, here) " <<
                                              "{\n                _16744290dd4cf3a3" <<
                                              "d72033b82f11df32f785b50239268efb173c" <<
                                              "e9ac269714e5.send_to_sink(1);\n     " <<
                                              "           return false;\n            }",
                               arguments: %w(some-arg arguments-arg here-arg)
                           ]
                       ]
            ]

            dom.execution_flow_sinks = sink
            expect(dom.execution_flow_sinks).to eq(sink)
        end
    end

    describe '#transitions=' do
        it 'sets #transitions' do
            transitions = [ { element: :stuffed } ]

            dom.transitions = transitions
            expect(dom.transitions).to eq(transitions)
        end
    end

    describe '#skip_states=' do
        it 'sets #skip_states' do
            skip_states = Arachni::Support::LookUp::HashSet.new.tap { |h| h << 0 }

            dom.skip_states = skip_states
            expect(dom.skip_states).to eq(skip_states)
        end
    end

    describe '#depth' do
        it 'returns the amount of DOM transitions' do
            dom.transitions = [
                { "http://test.com/"                 => :request },
                { :page                              => :load },
                { "<body onload='loadStuff();'>"     => :onload },
                { "http://test.com/ajax"             => :request },
                { "<a href='javascript:clickMe();'>" => :click },
            ].map { |t| described_class::Transition.new *t.first }

            expect(dom.depth).to eq(3)
        end
    end

    describe '#push_transition' do
        it 'pushes a state transition' do
            transitions = [
                { element: :stuffed },
                { element2: :stuffed2 }
            ].each do |t|
                empty_dom.push_transition described_class::Transition.new( *t.first )
            end

            expect(empty_dom.transitions).to eq(transitions.map { |t| described_class::Transition.new *t.first })
        end
    end

    describe '#state' do
        it 'returns a Page::DOM with enough info to reproduce the current state' do
            expect(dom.digest).to_not be_empty
            expect(dom.transitions).to_not be_empty
            expect(dom.data_flow_sinks).to_not be_empty
            expect(dom.execution_flow_sinks).to_not be_empty

            state = dom.state

            expect(state.page).to be_nil
            expect(state.url).to eq dom.url
            expect(state.digest).to eq dom.digest
            expect(state.transitions).to eq dom.transitions
            expect(state.skip_states).to eq dom.skip_states
            expect(state.data_flow_sinks).to be_empty
            expect(state.execution_flow_sinks).to be_empty
        end
    end

    describe '#to_hash' do
        it 'returns a hash with DOM data' do
            data = {
                url:         'http://test/dom',
                cookies:     [
                    Arachni::Element::Cookie.new(
                        url:    'http://test/dom',
                        inputs: { 'name' => 'val' }
                    )
                ],
                skip_states: Arachni::Support::LookUp::HashSet.new.tap { |h| h << 0 },
                transitions: [
                    { element:  :stuffed },
                    { element2: :stuffed2 }
                ].map { |t| described_class::Transition.new *t.first },
                data_flow_sinks:      [Factory[:data_flow]],
                execution_flow_sinks: [Factory[:execution_flow]]
            }

            empty_dom.url = data[:url]
            data[:transitions].each do |t|
                empty_dom.push_transition t
            end
            empty_dom.cookies = data[:cookies]
            empty_dom.skip_states = data[:skip_states]
            empty_dom.data_flow_sinks = data[:data_flow_sinks]
            empty_dom.execution_flow_sinks = data[:execution_flow_sinks]

            expect(empty_dom.to_h).to eq({
                url:                  data[:url],
                cookies:              data[:cookies].map(&:to_hash),
                transitions:          data[:transitions].map(&:to_hash),
                digest:               empty_dom.digest,
                skip_states:          data[:skip_states],
                data_flow_sinks:      data[:data_flow_sinks].map(&:to_hash),
                execution_flow_sinks: data[:execution_flow_sinks].map(&:to_hash)
            })
        end
        it 'is aliased to #to_h' do
            expect(empty_dom.to_h).to eq(empty_dom.to_h)
        end
    end

    describe '#hash' do
        it 'calculates a hash based on #digest' do
            dom  = empty_dom.dup
            dom.digest = 'stuff'

            dom2 = empty_dom.dup
            dom2.digest = 'stuff'

            expect(dom.hash).to eq(dom2.hash)

            dom2.digest = 'other stuff'
            expect(dom.hash).not_to eq(dom2.hash)
        end
    end

    describe '#restore' do
        context 'when the state can be restored by #url' do
            it 'loads the #url' do
                url = "#{@url}restore/by-url"

                browser.load "#{@url}restore/by-url"
                pages = browser.explore_and_flush
                page  = pages.last

                expect(page.url).to eq(url)
                expect(page.dom.url).to eq("#{url}#destination")
                expect(page.body).to include 'final-vector'

                page.dom.transitions.clear
                expect(page.dom.transitions).to be_empty

                browser.load page
                expect(browser.source).to include 'final-vector'
            end
        end

        context 'when the state cannot be restored by URL' do
            it 'replays its #transitions' do
                url = "#{@url}restore/by-transitions"

                browser.load url
                page = browser.explore_and_flush.last

                expect(page.url).to eq(url)
                expect(page.dom.url).to eq("#{url}#destination")
                expect(page.body).to include 'final-vector'

                browser.load page
                expect(browser.source).to include 'final-vector'

                page.dom.transitions.clear
                expect(page.dom.transitions).to be_empty

                browser.load page
                expect(browser.source).not_to include 'final-vector'
            end
        end

        context 'when a transition could not be replayed' do
            it 'returns nil' do
                allow_any_instance_of(Arachni::Page::DOM::Transition).to receive(:play){ false }

                browser.load "#{@url}restore/by-transitions"
                page = browser.explore_and_flush.last

                expect(page.dom.restore( browser )).to be_nil
            end
        end
    end

end
