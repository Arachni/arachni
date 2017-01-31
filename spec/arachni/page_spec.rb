require 'spec_helper'

describe Arachni::Page do

    def create_page( options = {} )
        described_class.new(
            response: Arachni::HTTP::Response.new(
                request: Factory[:request],
                code:    200,
                url:     'http://a-url.com/?myvar=my%20value',
                body:    options[:body],
                headers: options[:headers],
            ),
            dom: {
                url:         'http://a-url.com/#/stuff?myvar=my%20value',
                transitions: [ described_class::DOM::Transition.new( :page, :load )]
            }
        )
    end

    let(:url) { Arachni::Utilities.normalize_url web_server_url_for( :parser ) }
    let(:response) { Factory[:response] }
    let(:page) { Factory[:page] }
    let(:page_with_nonces) { described_class.from_url( url + 'with_nonce' ) }
    let(:rpc_subject) do
        page_with_nonces.dom.digest = 'stuff'

        # Load all elements in their caches.
        page_with_nonces.elements

        page_with_nonces.do_not_audit_elements

        dom = Factory[:dom]
        page_with_nonces.dom.transitions = dom.transitions
        page_with_nonces.dom.data_flow_sinks = dom.data_flow_sinks
        page_with_nonces.dom.execution_flow_sinks = dom.execution_flow_sinks

        # Assign external forms.
        page_with_nonces.forms = page_with_nonces.forms

        page_with_nonces.update_element_audit_whitelist page_with_nonces.elements.first

        page_with_nonces
    end
    let(:data) { subject.to_rpc_data }

    subject { page }

    it "supports #{Arachni::RPC::Serializer}" do
        page_with_nonces.forms = page_with_nonces.forms
        expect(page_with_nonces).to eq(Arachni::RPC::Serializer.deep_clone( page_with_nonces ))
    end

    describe '#to_rpc_data' do
        subject { rpc_subject }

        it "includes 'metadata'" do
            expect(data['metadata']).to eq(subject.metadata)
        end

        %w(response dom).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute]).to eq(subject.send( attribute ).to_rpc_data)
            end
        end

        it "includes 'forms'" do
            expect(data['forms']).to eq(subject.forms.map(&:to_rpc_data))
        end

        it "includes 'do_not_audit_elements'" do
            expect(data['do_not_audit_elements']).to be_truthy
        end

        it "includes 'element_audit_whitelist'" do
            expect(data['element_audit_whitelist']).to eq(subject.element_audit_whitelist.to_a)
        end

        it "does not include 'cookie_jar'" do
            expect(data).not_to include 'cookie_jar'
        end
    end

    describe '.from_rpc_data' do
        subject { rpc_subject }
        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(response dom metadata forms).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored.send( attribute )).to eq(subject.send( attribute ))
            end
        end

        it "restores #{described_class::DOM}#page" do
            expect(restored.dom.page).to eq(subject)
        end

        it "restores 'do_not_audit_elements'" do
            expect(restored.instance_variable_get(:@do_not_audit_elements)).to be_truthy
        end

        it "restores 'element_audit_whitelist'" do
            expect(restored.element_audit_whitelist).to eq(subject.element_audit_whitelist)
        end

        it 'restores Arachni::Element::Form#node of #forms' do
            form = subject.forms.last
            expect(form.node).to be_kind_of Arachni::Parser::Nodes::Element
            expect(form.node).to be_truthy

            expect(restored.forms.last.node.to_s).to eq(form.node.to_s)
        end

        it 'restores Arachni::Element::Link#node of #links' do
            link = subject.links.last
            expect(link.node).to be_kind_of Arachni::Parser::Nodes::Element
            expect(link.node).to be_truthy

            expect(restored.links.last.node.to_s).to eq(link.node.to_s)
        end

        context 'Arachni::Page::DOM' do
            [:url, :skip_states, :transitions, :data_flow_sinks, :execution_flow_sinks].each do |m|
                it "restores ##{m}" do
                    # Make sure we're not comparing nils.
                    expect(subject.dom.send( m )).to be_truthy

                    # Make sure we're not comparing empty stuff.
                    if (enumerable = restored.dom.send( m )).is_a? Enumerable
                        expect(enumerable).to be_any
                    end

                    expect(restored.dom.send( m )).to eq(subject.dom.send( m ))
                end
            end
        end

    end

    describe '#initialize' do
        describe 'option' do
            describe ':response' do
                it 'uses it to populate the page data' do
                    page   = described_class.new( response: response )
                    parser = Arachni::Parser.new( response )

                    expect(page.url).to eq(parser.url)
                    expect(page.method).to eq(parser.response.request.method)
                    expect(page.response).to eq(parser.response)
                    expect(page.body).to eq(parser.response.body)
                    expect(page.query_vars).to eq(parser.link_vars)
                    expect(page.paths).to eq(parser.paths)
                    expect(page.links).to eq(parser.links)
                    expect(page.forms).to eq(parser.forms)
                    expect(page.cookies).to eq(parser.cookies_to_be_audited)
                    expect(page.headers).to eq(parser.headers)
                    expect(page.cookie_jar).to eq(parser.cookie_jar)
                    expect(page.text?).to eq(parser.text?)
                end
            end

            describe ':parser' do
                it 'uses it to populate the page data' do
                    parser = Arachni::Parser.new( response )
                    page   = described_class.new( parser: parser )

                    expect(page.url).to eq(parser.url)
                    expect(page.method).to eq(parser.response.request.method)
                    expect(page.response).to eq(parser.response)
                    expect(page.body).to eq(parser.response.body)
                    expect(page.query_vars).to eq(parser.link_vars)
                    expect(page.paths).to eq(parser.paths)
                    expect(page.links).to eq(parser.links)
                    expect(page.forms).to eq(parser.forms)
                    expect(page.cookies).to eq(parser.cookies_to_be_audited)
                    expect(page.headers).to eq(parser.headers)
                    expect(page.cookie_jar).to eq(parser.cookie_jar)
                    expect(page.text?).to eq(parser.text?)
                end
            end

            describe ':dom' do
                it 'uses it to populate the DOM data' do
                    dom = described_class.new(
                        url:      'http://test/',
                        dom:      {
                            url:    'http://test/#/stuff',
                            transitions: [
                                page: :load
                            ]
                        }
                    ).dom

                    expect(dom.url).to eq('http://test/#/stuff')
                    expect(dom.transitions).to eq([ page: :load ])
                end
            end
        end

        context 'when called without options' do
            it 'raises ArgumentError' do
                expect{ described_class.new }.to raise_error ArgumentError
            end
        end

        context 'when called with empty options' do
            it 'raises ArgumentError' do
                expect{ described_class.new({}) }.to raise_error ArgumentError
            end
        end
    end

    describe '#element_audit_whitelist' do
        describe 'by default' do
            it 'returns an empty Set' do
                expect(subject.element_audit_whitelist).to be_empty
                expect(subject.element_audit_whitelist).to be_kind_of Set
            end
        end
    end

    describe '#performer' do
        it "returns the #{Arachni::HTTP::Request}#performer" do
            allow(page.request).to receive(:performer){ :stuff }
            expect(subject.performer).to eq(:stuff)
        end
    end

    describe '#update_element_audit_whitelist' do
        context 'when passed a' do
            context 'Arachni::Element::Capabilities::Auditable' do
                it 'updates the #element_audit_whitelist' do
                    subject.update_element_audit_whitelist subject.elements.first
                    expect(subject.element_audit_whitelist).to include subject.elements.first.coverage_hash
                end
            end

            context 'Integer' do
                it 'updates the #element_audit_whitelist' do
                    subject.update_element_audit_whitelist subject.elements.first.coverage_hash
                    expect(subject.element_audit_whitelist).to include subject.elements.first.coverage_hash
                end
            end

            context 'Array' do
                context 'Arachni::Element::Capabilities::Auditable' do
                    it 'updates the #element_audit_whitelist' do
                        subject.update_element_audit_whitelist [subject.elements[0],subject.elements[1]]
                        expect(subject.element_audit_whitelist).to include subject.elements[0].coverage_hash
                        expect(subject.element_audit_whitelist).to include subject.elements[1].coverage_hash
                    end
                end

                context 'Integer' do
                    it 'updates the #element_audit_whitelist' do
                        subject.update_element_audit_whitelist [subject.elements[0].coverage_hash, subject.elements[1].coverage_hash]
                        expect(subject.element_audit_whitelist).to include subject.elements[0].coverage_hash
                        expect(subject.element_audit_whitelist).to include subject.elements[1].coverage_hash
                    end
                end
            end
        end
    end

    describe '#do_not_audit_elements' do
        it 'forces #audit_element? to always return false' do
            subject.do_not_audit_elements
            expect(subject.element_audit_whitelist).to be_empty
            expect(subject.audit_element?( subject.elements.first )).to be_falsey

            subject.update_element_audit_whitelist subject.elements.first
            expect(subject.audit_element?( subject.elements.first )).to be_falsey
        end
    end

    describe '#audit_element?' do
        context 'when there is no #element_audit_whitelist' do
            it 'returns true' do
                expect(subject.element_audit_whitelist).to be_empty
                expect(subject.audit_element?( subject.elements.first )).to be_truthy
            end
        end

        context 'when there is an #element_audit_whitelist' do
            context 'and the element is in it' do
                context 'represented by' do
                    context 'Integer' do
                        it 'returns true' do
                            subject.update_element_audit_whitelist subject.elements.first
                            expect(subject.audit_element?( subject.elements.first.coverage_hash )).to be_truthy
                        end
                    end

                    context 'Arachni::Element::Capabilities::Auditable' do
                        it 'returns true' do
                            subject.update_element_audit_whitelist subject.elements.first
                            expect(subject.audit_element?( subject.elements.first )).to be_truthy
                        end
                    end
                end
            end
            context 'and the element is not in it' do
                context 'represented by' do
                    context 'Integer' do
                        it 'returns false' do
                            subject.update_element_audit_whitelist subject.elements.first
                            expect(subject.audit_element?( subject.elements.last.coverage_hash )).to be_falsey
                        end
                    end

                    context 'Arachni::Element::Capabilities::Auditable' do
                        it 'returns false' do
                            subject.update_element_audit_whitelist subject.elements.first
                            expect(subject.audit_element?( subject.elements.last )).to be_falsey
                        end
                    end
                end
            end
        end
    end

    describe '#response' do
        it 'returns the HTTP response for that page' do
            expect(page.response).to eq(response)
        end
    end

    describe '#request' do
        it 'returns the HTTP request for that page' do
            expect(page.request).to eq(response.request)
        end
    end

    describe '#body=' do
        it 'sets the #body' do
            subject.body = 'stuff'
            expect(subject.body).to eq('stuff')
        end
        it 'sets the applicable #parser body' do
            subject.body = 'stuff'
            expect(subject.parser.body).to eq('stuff')
        end
        it 'calls #clear_cache' do
            expect(subject).to receive(:clear_cache)
            subject.body = 'stuff'
        end
        it 'resets the #has_script? flag' do
            page = create_page(
                body:    'stuff',
                headers: { 'content-type' => 'text/html' }
            )

            expect(page.has_script?).to be_falsey
            page.body = '<script></script>'
            expect(page.has_script?).to be_truthy
        end
    end

    describe '#parser' do
        it 'is lazy-loaded' do
            expect(subject.cache[:parser]).to be_nil
            expect(subject.parser).to be_kind_of Arachni::Parser
            expect(subject.cache[:parser]).to eq(subject.parser)
        end

        it 'is cached' do
            s = subject.dup

            s.parser
            expect(Arachni::Parser).not_to receive(:new)
            s.parser
        end

        it 'uses the Page#body instead of HTTP::Response#body' do
            page = described_class.new(
                response: response.tap { |r| r.body = 'blah'},
                body:     'stuff'
            )
            expect(page.body).to eq('stuff')
            expect(page.parser.body).to eq(page.body)

            page.body = 'stuff2'
            expect(page.parser.body).to eq(page.body)
        end
    end

    [:links, :forms, :cookies, :headers].each do |element|
        parser_method = element
        parser_method = :cookies_to_be_audited if element == :cookies

        describe "##{element}" do
            it 'sets the correct #page association' do
                subject.send(element).each { |e| expect(e.page).to eq(subject) }
            end

            it 'is lazy-loaded' do
                expect(subject.cache[element]).to be_nil
                expect(subject.send(element)).to be_any
                expect(subject.cache[element]).to eq(subject.send(element))
            end

            it 'delegates to Parser' do
                s = subject.dup
                expect(s.parser).to receive(parser_method).and_return([])
                s.send(element)
            end

            it 'is cached' do
                s = subject.dup

                s.send(element)
                expect(s.parser).not_to receive(parser_method)
                s.send(element)
            end

            it 'is frozen' do
                expect(subject.send(element)).to be_frozen
            end
        end

        describe "##{element}=" do
            element_klass = Arachni::Element.const_get( element.to_s[0...-1].capitalize )
            let(:klass) { element_klass }
            let(:list) { [element_klass.new( url: subject.url, inputs: { test: 1 } )] }

            it "sets the page ##{element}" do
                expect(subject.send(element)).to be_any
                subject.send("#{element}=", [])
                expect(subject.send(element)).to be_empty
                subject.send("#{element}=", list)
                expect(subject.send(element)).to eq(list)
            end

            it 'caches it' do
                expect(subject.cache[element]).to be_nil
                subject.send("#{element}=", list)
                expect(subject.cache[element]).to eq(list)
            end

            it "sets the #page association on the #{element_klass} elements" do
                subject.send( "#{element}=", list )
                expect(subject.send(element).first.page).to eq(subject)
            end

            it 'freezes the list' do
                expect(subject.send(element)).to be_frozen
            end
        end
    end

    describe '#platforms' do
        it 'returns platforms for the given page' do
            expect(page.platforms).to be_kind_of Arachni::Platform::Manager
        end
    end

    describe '#has_script?' do
        context 'when the page has' do
            context '<script>' do
                it 'returns true' do
                    expect(create_page(
                        body:    '<Script>var i = '';</script>',
                        headers: { 'content-type' => 'text/html' }
                    ).has_script?).to be_truthy
                end
            end
            context 'elements with event attributes' do
                it 'returns true' do
                    expect(create_page(
                        body:    '<a onMouseOver="doStuff();">Stuff</a>',
                        headers: { 'content-type' => 'text/html' }
                    ).has_script?).to be_truthy
                end
            end
            context 'anchors with javacript: in href' do
                it 'returns true' do
                    expect(create_page(
                        body:    '<a href="JavaScript:doStuff();">Stuff</a>',
                        headers: { 'content-type' => 'text/html' }
                    ).has_script?).to be_truthy
                end
            end
            context 'forms with javacript: in action' do
                it 'returns true' do
                    expect(create_page(
                        body:    '<form action="javascript:doStuff();"></form>',
                        headers: { 'content-type' => 'text/html' }
                    ).has_script?).to be_truthy
                end
            end
            context 'no client-side code' do
                it 'returns false' do
                    expect(create_page( body: 'stuff' ).has_script?).to be_falsey
                end
            end
        end
    end

    describe '#has_elements?' do
        context 'when the page has any of the given elements' do
            it 'returns true' do
                expect(create_page(
                    body:    '<fOrM></form>',
                    headers: { 'content-type' => 'text/html' }
                ).has_elements?( 'form', 'script' )).to be_truthy
            end
        end

        context 'when the page has none of the given elements' do
            it 'returns false' do
                expect(create_page(
                    body:    '<fOrM></form>',
                    headers: { 'content-type' => 'text/html' }
                ).has_elements?( 'a', 'script' )).to be_falsey
            end
        end
    end

    describe '#text?' do
        context 'when the HTTP response is text/html' do
            it 'returns true' do
                expect(Arachni::Parser.new( Factory[:html_response] ).page.text?).to be_truthy
            end
        end

        context 'when the response is not text based' do
            it 'returns false' do
                expect(Arachni::Parser.new( Factory[:binary_response] ).page.text?).to be_falsey
            end
        end
    end

    describe '#==' do
        context 'when the pages are different' do
            it 'returns false' do
                p = create_page( body: 'stuff here' )
                p.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]
                p.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]
                p.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]
                p.dom.push_transition described_class::DOM::Transition.new( "<a href='#' id='stuff'>", :onclick )

                c = p.dup
                c.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                expect(c).not_to eq(p)

                c = p.dup
                c.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                expect(c).not_to eq(p)

                c = p.dup
                c.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                expect(c).not_to eq(p)

                c = p.dup
                c.dom.push_transition described_class::DOM::Transition.new( "<a href='#' id='stuff'>", :onhover )
                expect(c).not_to eq(p)
            end
        end
        context 'when the pages are identical' do
            it 'returns true' do
                p = create_page( body: 'stuff here')
                p.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]
                p.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]
                p.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]

                c = p.dup
                expect(c).to eq(p)

                p.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                p.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                p.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                p.dom.push_transition described_class::DOM::Transition.new( "<a href='#' id='stuff'>", :onhover )

                c.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.dom.push_transition described_class::DOM::Transition.new( "<a href='#' id='stuff'>", :onhover )

                expect(c).to eq(p)
            end
        end
    end

    describe '#eql?' do
        context 'when the pages are different' do
            it 'returns false' do
                p = create_page( body: 'stuff here')
                p.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]
                p.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]
                p.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]

                c = p.dup
                c.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                expect(c).not_to eql p

                c = p.dup
                c.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                expect(c).not_to eql p

                c = p.dup
                c.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                expect(c).not_to eql p
            end
        end
        context 'when the pages are identical' do
            it 'returns true' do
                p = create_page( body: 'stuff here')
                p.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]
                p.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]
                p.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]

                c = p.dup
                expect(c).to eql p

                c = p.dup
                p.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                p.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                p.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]

                c.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                expect(c).to eql p
            end
        end
    end

    describe '#title' do
        context 'when the page has a title' do
            it 'returns the page title' do
                title = 'Stuff here'
                expect(create_page( body: "<title>#{title}</title>" ).title).to eq(title)
                expect(create_page( body: '<title></title>' ).title).to eq('')
            end
        end
        context 'when the page does not have a title' do
            it 'returns nil' do
                expect(create_page.title).to be_nil
                expect(create_page( body: '' ).title).to be_nil
            end
        end
    end

    describe '#elements' do
        it 'returns all page elements' do
            expect(page.elements).to eq(page.links | page.forms | page.cookies | page.headers)
        end
    end

    describe '#elements_within_scope' do
        it 'returns all elements that are within scope' do
            Arachni::Options.audit.elements :links, :forms, :cookies, :headers

            elements = page.elements
            element = elements.pop
            allow(element.scope).to receive(:in?) { false }

            expect(page.elements_within_scope).to eq(elements - [element])
        end
    end

    describe '#clear_cache' do
        it 'returns self' do
            expect(subject.clear_cache).to eq(subject)
        end

        it 'clears the #cache' do
            cachable = [:query_vars, :links, :forms, :cookies, :headers, :paths,
                        :document, :parser]

            expect(subject.cache.keys).to be_empty

            cachable.each do |attribute|
                subject.send attribute
            end

            expect(subject.cache.keys.sort).to eq(cachable.sort)
            subject.clear_cache
            expect(subject.cache.keys).to be_empty
        end

        [:links, :forms, :cookies, :headers].each do |type|
            context "when ##{type} have been externally set" do
                it 'does not empty their cache' do
                    subject.send("#{type}=", subject.send(type))
                    subject.clear_cache
                    expect(subject.cache.keys).to eq([type])
                    expect(subject.cache[type]).to eq(subject.send(type))
                end
            end
        end

        context 'when #forms have nonces' do
            it 'preserves them' do
                expect(page_with_nonces.forms.map { |f| f.nonce_name }.sort).
                    to eq(%w(nonce nonce2).sort)

                page_with_nonces.clear_cache

                expect(page_with_nonces.forms.map { |f| f.nonce_name }.sort).
                    to eq(%w(nonce nonce2).sort)
            end
        end
    end

    describe '#prepare_for_report' do
        it 'clears the #cache' do
            s = subject.dup
            s.prepare_for_report
            expect(s.cache).to be_empty
        end

        it 'removes #dom#digest' do
            subject.dom.digest = 'stuff'
            subject.prepare_for_report
            expect(subject.dom.digest).to be_nil
        end

        it 'removes #dom#skip_states' do
            expect(subject.dom.skip_states).to be_truthy
            subject.prepare_for_report
            expect(subject.dom.digest).to be_nil
        end

        it 'returns self' do
            expect(subject.prepare_for_report).to eq(subject)
        end

        context 'if the body is not #text?' do
            let(:page) { Factory[:binary_response].to_page }

            it 'clears it' do
                expect(page.body).not_to be_empty
                page.prepare_for_report
                expect(page.body).to be_empty
            end

            it 'clears the #response#body' do
                expect(page.response.body).not_to be_empty
                page.prepare_for_report
                expect(page.response.body).to be_empty
            end
        end
    end

    describe '#update_metadata' do
        it 'updates #metadata from #cache elements' do
            subject.metadata.clear

            form            = subject.forms.first
            form.nonce_name = form.inputs.keys.first
            form.skip_dom   = true

            subject.update_metadata

            expect(subject.metadata['form']['nonce_name'][form.coverage_hash]).to eq(form.inputs.keys.first)
            expect(subject.metadata['form']['skip_dom'][form.coverage_hash]).to eq(true)
        end
    end

    describe '#reload_metadata' do
        it 'updates #cache elements from #metadata' do
            subject.metadata.clear

            form            = subject.forms.first
            form.nonce_name = form.inputs.keys.first
            form.skip_dom   = true

            subject.update_metadata
            subject.clear_cache

            form            = subject.forms.first
            form.nonce_name = nil
            form.skip_dom   = nil

            subject.reload_metadata

            expect(form.nonce_name).to eq(form.inputs.keys.first)
            expect(form.skip_dom).to eq(true)
        end
    end

    describe '#import_metadata' do
        it 'imports #metadata from the given page' do
            subject.metadata.clear

            dpage = subject.dup
            dpage.metadata.clear

            form            = dpage.forms.first
            form.nonce_name = form.inputs.keys.first
            form.skip_dom   = true

            dpage.update_metadata

            subject.import_metadata( dpage )

            expect(subject.metadata).to eq(dpage.metadata)
        end

        context 'when a type is given' do
            it 'only imports that type of data' do
                subject.metadata.clear

                dpage = subject.dup
                dpage.metadata.clear

                form            = dpage.forms.first
                form.nonce_name = form.inputs.keys.first
                form.skip_dom   = true

                dpage.update_metadata

                subject.import_metadata( dpage, :skip_dom )

                expect(subject.metadata['form']['nonce_name']).to be_nil
                expect(subject.metadata['form']['skip_dom'][form.coverage_hash]).to eq(true)
            end
        end
    end

    describe '#to_h' do
        it 'converts the page to a hash' do
            expect(subject.to_h).to be_kind_of Hash

            subject.to_h.each do |k, v|
                expect(v).to eq(subject.send(k))
            end
        end

        [:document, :do_not_audit_elements, :has_custom_elements, :parser].each do |k|
            it "does not include ':#{k}'" do
                expect(subject.to_h).not_to include k
            end
        end
    end

    [:dup, :deep_clone].each do |method|
        describe "##{method}" do
            it 'returns a copy of the page' do
                dupped = subject.send(method)
                expect(dupped).to eq(subject)
            end

            [:response, :metadata, :body, :links, :forms, :cookies, :headers, :cookie_jar, :paths].each do |m|
                it "preserves ##{m}" do
                    dupped = subject.send(method)

                    # Make sure we're not comparing nils.
                    expect(subject.send( m )).to be_truthy

                    # Make sure we're not comparing empty stuff.
                    if (enumerable = dupped.send( m )).is_a? Enumerable
                        expect(enumerable).to be_any
                    end

                    expect(dupped.send( m )).to eq(subject.send( m ))
                end
            end

            it 'preserves #element_audit_whitelist' do
                subject.update_element_audit_whitelist subject.elements.first
                dupped = subject.send(method)
                expect(dupped.element_audit_whitelist).to include subject.elements.first.coverage_hash
            end

            it 'preserves Arachni::Element::Form#node of #forms' do
                form = subject.forms.last
                expect(form.node).to be_kind_of Arachni::Parser::Nodes::Element
                expect(form.node).to be_truthy

                expect(subject.send(method).forms.last.node.to_s).to eq(form.node.to_s)
            end

            it 'preserves Arachni::Element::Link#node of #links' do
                link = subject.links.last
                expect(link.node).to be_kind_of Arachni::Parser::Nodes::Element
                expect(link.node).to be_truthy

                expect(subject.send(method).links.last.node.to_s).to eq(link.node.to_s)
            end

            it 'preserves #page associations for #elements' do
                dup = subject.send(method)
                expect(dup.elements).to be_any
                dup.elements.each { |e| expect(e.page).to eq(subject) }
            end

            context 'when #forms have nonces' do
                it 'preserves them' do
                    expect(page_with_nonces.forms.map { |f| f.nonce_name }.sort).to eq(%w(nonce nonce2).sort)
                    expect(page_with_nonces.send(method).forms.map { |f| f.nonce_name }.sort).to eq(%w(nonce nonce2).sort)
                end
            end

            context 'Arachni::Page::DOM' do
                [:url, :skip_states, :transitions, :data_flow_sinks, :execution_flow_sinks].each do |m|
                    it "preserves ##{m}" do
                        dupped = subject.send(method)

                        # Make sure we're not comparing nils.
                        expect(subject.dom.send( m )).to be_truthy

                        # Make sure we're not comparing empty stuff.
                        if (enumerable = dupped.dom.send( m )).is_a? Enumerable
                            expect(enumerable).to be_any
                        end

                        expect(dupped.dom.send( m )).to eq(subject.dom.send( m ))
                    end
                end
            end

        end
    end

    describe '.from_url' do
        it 'returns a page from the given url' do
            expect(described_class.from_url( url + 'with_nonce' )).to be_kind_of described_class
        end

        context 'when #forms have nonces' do
            it 'preserves them' do
                expect(described_class.from_url( url + 'with_nonce' ).forms.
                    map { |f| f.nonce_name }.sort).to eq(%w(nonce nonce2).sort)
            end
        end
    end

    describe '.from_data' do
        it 'creates a page from the given data' do
            elem_opts = {
                url: 'http://test.com',
                inputs: { 'test' => 'stuff' }
            }

            data = {
                url:  'http://test/',
                body: 'http://test/1 http://test/2',
                paths: [ 'http://test/1', 'http://test/2' ],
                links: [Arachni::Element::Link.new( elem_opts )],
                forms: [Arachni::Element::Form.new( elem_opts )],
                cookies: [Arachni::Element::Cookie.new( elem_opts )],
                cookie_jar: [
                    Arachni::Element::Cookie.new( elem_opts ),
                    Arachni::Element::Cookie.new( elem_opts )
                ],
                headers: [Arachni::Element::Header.new( elem_opts )],
                response: {
                    code: 200
                },

                dom:     {
                    url:         'http://test/#/stuff',
                    transitions: [ described_class::DOM::Transition.new( :page, :load )]
                }
            }

            page = Arachni::Page.from_data( data )
            expect(page.code).to eq(data[:response][:code])
            expect(page.url).to eq(data[:url])
            expect(page.body).to eq(data[:body])
            expect(page.paths).to eq(data[:paths])

            expect(page.links).to eq(data[:links])
            expect(page.forms).to eq(data[:forms])
            expect(page.cookies).to eq(data[:cookies])
            expect(page.headers).to eq(data[:headers])

            expect(page.cookie_jar).to eq(data[:cookie_jar])

            expect(page.response.code).to eq(data[:response][:code])
            expect(page.response.url).to eq(data[:url])
            expect(page.response.body).to eq(data[:body])
            expect(page.response.request.url).to eq(data[:url])

            expect(page.dom.url).to eq(data[:dom][:url])
            expect(page.dom.transitions).to eq(data[:dom][:transitions])
        end

        context 'when no HTTP data is given' do
            it 'creates them with default values' do
                data = {
                    url:  'http://test/',
                    body: 'test'
                }

                page = Arachni::Page.from_data( data )
                expect(page.url).to eq(data[:url])
                expect(page.body).to eq(data[:body])
                expect(page.code).to eq(200)

                expect(page.links).to eq([])
                expect(page.forms).to eq([])
                expect(page.cookies).to eq([])
                expect(page.headers).to eq(page.parser.headers)

                expect(page.cookie_jar).to eq([])

                expect(page.response.code).to eq(200)
                expect(page.response.url).to eq(data[:url])
                expect(page.response.body).to eq(data[:body])
                expect(page.response.request.url).to eq(data[:url])
            end
        end
    end

    describe '.from_response' do
        it 'creates a page from an HTTP response' do
            page = Arachni::Page.from_response( response )
            expect(page.class).to eq(Arachni::Page)
            parser = Arachni::Parser.new( response )

            expect(page.url).to eq(parser.url)
            expect(page.method).to eq(parser.response.request.method)
            expect(page.response).to eq(parser.response)
            expect(page.body).to eq(parser.response.body)
            expect(page.query_vars).to eq(parser.link_vars)
            expect(page.paths).to eq(parser.paths)
            expect(page.links).to eq(parser.links)
            expect(page.forms).to eq(parser.forms)
            expect(page.cookies).to eq(parser.cookies_to_be_audited)
            expect(page.headers).to eq(parser.headers)
            expect(page.cookie_jar).to eq(parser.cookie_jar)
            expect(page.text?).to eq(parser.text?)

        end
    end

end
