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

    before( :each ) do
        @browser = Arachni::Browser.new
    end

    after( :each ) do
        Arachni::Options.reset
        Arachni::Framework.reset
        @browser.shutdown
    end

    let( :dom ) { Factory[:dom] }
    let( :empty_dom ) { create_page.dom }
    subject { dom }

    it "supports #{Arachni::Serializer}" do
        subject.digest = 'stuff'
        subject.should == Arachni::Serializer.deep_clone( subject )
    end

    describe '#url' do
        it 'defaults to the page URL' do
            dom.url.should == create_page.url
        end
    end

    describe '#transitions' do
        it 'defaults to an empty Array' do
            empty_dom.transitions.should == []
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

            dom.playable_transitions.should ==  [
                { :page                              => :load },
                { "<body onload='loadStuff();'>"     => :onload },
                { "<a href='javascript:clickMe();'>" => :click },
            ].map { |t| described_class::Transition.new *t.first }
        end
    end

    describe '#data_flow_sink' do
        it 'defaults to an empty Array' do
            empty_dom.data_flow_sink.should == []
        end
    end

    describe '#data_flow_sink=' do
        it 'sets #data_flow_sink' do
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

            dom.data_flow_sink = sink
            dom.data_flow_sink.should == sink
        end
    end

    describe '#execution_flow_sink' do
        it 'defaults to an empty Array' do
            empty_dom.execution_flow_sink.should == []
        end
    end

    describe '#execution_flow_sink=' do
        it 'sets #execution_flow_sink' do
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

            dom.execution_flow_sink = sink
            dom.execution_flow_sink.should == sink
        end
    end

    describe '#transitions=' do
        it 'sets #transitions' do
            transitions = [ { element: :stuffed } ]

            dom.transitions = transitions
            dom.transitions.should == transitions
        end
    end

    describe '#skip_states=' do
        it 'sets #skip_states' do
            skip_states = Arachni::Support::LookUp::HashSet.new.tap { |h| h << 0 }

            dom.skip_states = skip_states
            dom.skip_states.should == skip_states
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

            dom.depth.should == 3
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

            empty_dom.transitions.should == transitions.map { |t| described_class::Transition.new *t.first }
        end
    end

    describe '#to_hash' do
        it 'returns a hash with DOM data' do
            data = {
                url:         'http://test/dom',
                skip_states: Arachni::Support::LookUp::HashSet.new.tap { |h| h << 0 },
                transitions: [
                    { element:  :stuffed },
                    { element2: :stuffed2 }
                ].map { |t| described_class::Transition.new *t.first },
                data_flow_sink:      ['stuff'],
                execution_flow_sink: ['stuff2']
            }

            empty_dom.url = data[:url]
            data[:transitions].each do |t|
                empty_dom.push_transition t
            end
            empty_dom.skip_states = data[:skip_states]
            empty_dom.data_flow_sink = data[:data_flow_sink]
            empty_dom.execution_flow_sink = data[:execution_flow_sink]

            empty_dom.to_h.should == data.merge( digest: empty_dom.digest )
        end
        it 'is aliased to #to_h' do
            empty_dom.to_h.should == empty_dom.to_h
        end
    end

    describe '#hash' do
        it 'calculates a hash based on #digest' do
            dom  = empty_dom.dup
            dom.digest = 'stuff'

            dom2 = empty_dom.dup
            dom2.digest = 'stuff'

            dom.hash.should == dom2.hash

            dom2.digest = 'other stuff'
            dom.hash.should_not == dom2.hash
        end
    end

    describe '#restore' do
        context 'when the state can be restored by #url' do
            it 'loads the #url' do
                url = "#{@url}restore/by-url"

                @browser.load "#{@url}restore/by-url"
                pages = @browser.explore_and_flush
                page  = pages.last


                page.url.should == url
                page.dom.url.should == "#{url}#destination"
                page.body.should include 'final-vector'

                page.dom.transitions.clear
                page.dom.transitions.should be_empty

                @browser.load page
                @browser.source.should include 'final-vector'
            end
        end

        context 'when the state cannot be restored by URL' do
            it 'replays its #transitions' do
                url = "#{@url}restore/by-transitions"

                @browser.load url
                page = @browser.explore_and_flush.last

                page.url.should == url
                page.dom.url.should == "#{url}#destination"
                page.body.should include 'final-vector'

                @browser.load page
                @browser.source.should include 'final-vector'

                page.dom.transitions.clear
                page.dom.transitions.should be_empty

                @browser.load page
                @browser.source.should_not include 'final-vector'
            end
        end
    end

end
