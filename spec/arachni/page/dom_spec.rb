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

    let( :dom ) { Factory[:dom] }
    let( :empty_dom ) { create_page.dom }

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

    describe '#replayable_transitions' do
        it 'returns replayable transitions' do
            dom.transitions = [
                { :page                              => :load },
                { "http://test.com/"                 => :request },
                { "<body onload='loadStuff();'>"     => :onload },
                { "http://test.com/ajax"             => :request },
                { "<a href='javascript:clickMe();'>" => :click },
            ].map { |t| described_class::Transition.new t }

            dom.replayable_transitions.should ==  [
                { "<body onload='loadStuff();'>"     => :onload },
                { "<a href='javascript:clickMe();'>" => :click },
            ].map { |t| described_class::Transition.new t }
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
            ].map { |t| described_class::Transition.new t }

            dom.depth.should == 3
        end
    end

    describe '#push_transition' do
        it 'pushes a state transition' do
            transitions = [
                { element: :stuffed },
                { element2: :stuffed2 }
            ].each do |transition|
                empty_dom.push_transition described_class::Transition.new( transition )
            end

            empty_dom.transitions.should == transitions.map { |t| described_class::Transition.new t }
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
                ].map { |t| described_class::Transition.new t },
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

            empty_dom.to_h.should == data
        end
        it 'is aliased to #to_h' do
            empty_dom.to_h.should == empty_dom.to_h
        end
    end

    describe '#hash' do
        it 'calculates a hash based on nodes' do
            body = <<-EOHTML
                Blah blah.

                <div id='my-div' class='stuff here'>
                    Text here.
                </div>
            EOHTML

            dom  = create_page( body: body ).dom
            dom2 = create_page( body: body ).dom

            dom.hash.should == dom2.hash

            body2 = <<-EOHTML
                <div id='my-div' class='stuff here'>
                    Different text here.
                </div>
            EOHTML

            dom  = create_page( body: body ).dom
            dom2 = create_page( body: body2 ).dom

            dom.hash.should == dom2.hash

            body2 = <<-EOHTML
                <div id='my-div' class='stuff here'>
                    Different text here.
                </div>
                <a href="stuff">Stuff</a>
            EOHTML

            dom  = create_page( body: body ).dom
            dom2 = create_page( body: body2 ).dom

            dom.hash.should_not == dom2.hash
        end

        it 'calculates a hash based on node attributes' do
            body = <<-EOHTML
                Blah blah.

                <div id='my-div' class='stuff here'>
                    Text here.
                </div>
            EOHTML

            body2 = <<-EOHTML
                Blah blah.

                <div id='div' class='here'>
                    Text here.
                </div>
            EOHTML

            dom  = create_page( body: body ).dom
            dom2 = create_page( body: body2 ).dom

            dom.hash.should_not == dom2.hash
        end

        it 'ignores paragraphs' do
            body = <<-EOHTML
                <p>Blah blah.</p>
            EOHTML

            body2 = <<-EOHTML
                <p>More blah blah.</p>
            EOHTML

            dom  = create_page( body: body ).dom
            dom2 = create_page( body: body2 ).dom

            dom.hash.should == dom2.hash
        end

        it 'ignores text' do
            body = <<-EOHTML
                Blah blah.

                <div id='my-div' class='stuff here'>
                    Text here.
                </div>
            EOHTML

            dom  = create_page( body: body ).dom
            dom2 = create_page( body: body ).dom

            dom.hash.should == dom2.hash

            body2 = <<-EOHTML
                <div id='my-div' class='stuff here'>
                    Different text here.
                </div>
            EOHTML

            dom  = create_page( body: body ).dom
            dom2 = create_page( body: body2 ).dom

            dom.hash.should == dom2.hash
        end

    end

end
