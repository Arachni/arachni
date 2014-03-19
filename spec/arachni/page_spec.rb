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

    let( :response ) { Factory[:response] }
    let( :page ) { Factory[:page] }
    subject { page }

    describe '#initialize' do
        describe 'option' do
            describe :response do
                it 'uses it to populate the page data' do
                    page   = described_class.new( response: response )
                    parser = Arachni::Parser.new( response )

                    page.url.should == parser.url
                    page.method.should == parser.response.request.method
                    page.response.should == parser.response
                    page.body.should == parser.response.body
                    page.query_vars.should == parser.link_vars
                    page.paths.should == parser.paths
                    page.links.should == parser.links
                    page.forms.should == parser.forms
                    page.cookies.should == parser.cookies_to_be_audited
                    page.headers.should == parser.headers
                    page.cookiejar.should == parser.cookie_jar
                    page.text?.should == parser.text?
                end
            end

            describe :parser do
                it 'uses it to populate the page data' do
                    parser = Arachni::Parser.new( response )
                    page   = described_class.new( parser: parser )

                    page.url.should == parser.url
                    page.method.should == parser.response.request.method
                    page.response.should == parser.response
                    page.body.should == parser.response.body
                    page.query_vars.should == parser.link_vars
                    page.paths.should == parser.paths
                    page.links.should == parser.links
                    page.forms.should == parser.forms
                    page.cookies.should == parser.cookies_to_be_audited
                    page.headers.should == parser.headers
                    page.cookiejar.should == parser.cookie_jar
                    page.text?.should == parser.text?
                end
            end

            describe :dom do
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

                    dom.url.should == 'http://test/#/stuff'
                    dom.transitions.should == [ page: :load ]
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
                subject.element_audit_whitelist.should be_empty
                subject.element_audit_whitelist.should be_kind_of Set
            end
        end
    end

    describe '#update_element_audit_whitelist' do
        context 'when passed a' do
            context Arachni::Element::Capabilities::Auditable do
                it 'updates the #element_audit_whitelist' do
                    subject.update_element_audit_whitelist subject.elements.first
                    subject.element_audit_whitelist.should include subject.elements.first.audit_scope_id
                end
            end

            context Integer do
                it 'updates the #element_audit_whitelist' do
                    subject.update_element_audit_whitelist subject.elements.first.audit_scope_id
                    subject.element_audit_whitelist.should include subject.elements.first.audit_scope_id
                end
            end

            context Array do
                context Arachni::Element::Capabilities::Auditable do
                    it 'updates the #element_audit_whitelist' do
                        subject.update_element_audit_whitelist [subject.elements[0],subject.elements[1]]
                        subject.element_audit_whitelist.should include subject.elements[0].audit_scope_id
                        subject.element_audit_whitelist.should include subject.elements[1].audit_scope_id
                    end
                end

                context Integer do
                    it 'updates the #element_audit_whitelist' do
                        subject.update_element_audit_whitelist [subject.elements[0].audit_scope_id, subject.elements[1].audit_scope_id]
                        subject.element_audit_whitelist.should include subject.elements[0].audit_scope_id
                        subject.element_audit_whitelist.should include subject.elements[1].audit_scope_id
                    end
                end
            end
        end
    end

    describe '#do_not_audit_elements' do
        it 'forces #audit_element? to always return false' do
            subject.do_not_audit_elements
            subject.element_audit_whitelist.should be_empty
            subject.audit_element?( subject.elements.first ).should be_false

            subject.update_element_audit_whitelist subject.elements.first
            subject.audit_element?( subject.elements.first ).should be_false
        end
    end

    describe '#audit_element?' do
        context 'when there is no #element_audit_whitelist' do
            it 'returns true' do
                subject.element_audit_whitelist.should be_empty
                subject.audit_element?( subject.elements.first ).should be_true
            end
        end

        context 'when there is an #element_audit_whitelist' do
            context 'and the element is in it' do
                context 'represented by' do
                    context Integer do
                        it 'returns true' do
                            subject.update_element_audit_whitelist subject.elements.first
                            subject.audit_element?( subject.elements.first.audit_scope_id ).should be_true
                        end
                    end

                    context Arachni::Element::Capabilities::Auditable do
                        it 'returns true' do
                            subject.update_element_audit_whitelist subject.elements.first
                            subject.audit_element?( subject.elements.first ).should be_true
                        end
                    end
                end
            end
            context 'and the element is not in it' do
                context 'represented by' do
                    context Integer do
                        it 'returns false' do
                            subject.update_element_audit_whitelist subject.elements.first
                            subject.audit_element?( subject.elements.last.audit_scope_id ).should be_false
                        end
                    end

                    context Arachni::Element::Capabilities::Auditable do
                        it 'returns false' do
                            subject.update_element_audit_whitelist subject.elements.first
                            subject.audit_element?( subject.elements.last ).should be_false
                        end
                    end
                end
            end
        end
    end

    describe '#response' do
        it 'returns the HTTP response for that page' do
            page.response.should == response
        end
    end

    describe '#request' do
        it 'returns the HTTP request for that page' do
            page.request.should == response.request
        end
    end

    describe '#body=' do
        it 'sets the #body' do
            subject.body = 'stuff'
            subject.body.should == 'stuff'
        end
        it 'sets the applicable #parser body' do
            subject.body = 'stuff'
            subject.parser.body.should == 'stuff'
        end
        it 'calls #clear_cache' do
            subject.should receive(:clear_cache)
            subject.body = 'stuff'
        end
        it 'resets the #has_script? flag' do
            page = create_page(
                body:    'stuff',
                headers: { 'content-type' => 'text/html' }
            )

            page.has_script?.should be_false
            page.body = '<script></script>'
            page.has_script?.should be_true
        end
    end

    describe '#parser' do
        it 'is lazy-loaded' do
            subject.cache[:parser].should be_nil
            subject.parser.should be_kind_of Arachni::Parser
            subject.cache[:parser].should == subject.parser
        end

        it 'is cached' do
            s = subject.dup

            s.parser
            Arachni::Parser.should_not receive(:new)
            s.parser
        end

        it 'uses the Page#body instead of HTTP::Response#body' do
            page = described_class.new(
                response: response.tap { |r| r.body = 'blah'},
                body:     'stuff'
            )
            page.body.should == 'stuff'
            page.parser.body.should == page.body

            page.body = 'stuff2'
            page.parser.body.should == page.body
        end
    end

    [:links, :forms, :cookies, :headers].each do |element|
        parser_method = element
        parser_method = :cookies_to_be_audited if element == :cookies

        describe "##{element}" do
            it 'sets the correct #page association' do
                subject.send(element).each { |e| e.page.should == subject }
            end

            it 'is lazy-loaded' do
                subject.cache[element].should be_nil
                subject.send(element).should be_any
                subject.cache[element].should == subject.send(element)
            end

            it 'delegates to Parser' do
                s = subject.dup
                s.parser.should receive(parser_method).and_return([])
                s.send(element)
            end

            it 'is cached' do
                s = subject.dup

                s.send(element)
                s.parser.should_not receive(parser_method)
                s.send(element)
            end

            it 'is frozen' do
                subject.send(element).should be_frozen
            end
        end

        describe "##{element}=" do
            element_klass = Arachni::Element.const_get( element.to_s[0...-1].capitalize )
            let(:klass) { element_klass }
            let(:list) { [element_klass.new( url: subject.url, inputs: { test: 1 } )] }

            it "sets the page ##{element}" do
                subject.send(element).should be_any
                subject.send("#{element}=", [])
                subject.send(element).should be_empty
                subject.send("#{element}=", list)
                subject.send(element).should == list
            end

            it 'caches it' do
                subject.cache[element].should be_nil
                subject.send("#{element}=", list)
                subject.cache[element].should == list
            end

            it "sets the #page association on the #{element_klass} elements" do
                subject.send( "#{element}=", list )
                subject.send(element).first.page.should == subject
            end

            it 'freezes the list' do
                subject.send(element).should be_frozen
            end
        end
    end

    describe '#platforms' do
        it 'returns platforms for the given page' do
            page.platforms.should be_kind_of Arachni::Platform::Manager
        end
    end

    describe '#has_script?' do
        context 'when the page has' do
            context '<script>' do
                it 'returns true' do
                    create_page(
                        body:    '<Script>var i = '';</script>',
                        headers: { 'content-type' => 'text/html' }
                    ).has_script?.should be_true
                end
            end
            context 'elements with event attributes' do
                it 'returns true' do
                    create_page(
                        body:    '<a onmouseover="doStuff();">Stuff</a>',
                        headers: { 'content-type' => 'text/html' }
                    ).has_script?.should be_true
                end
            end
            context 'anchors with javacript: in href' do
                it 'returns true' do
                    create_page(
                        body:    '<a href="javascript:doStuff();">Stuff</a>',
                        headers: { 'content-type' => 'text/html' }
                    ).has_script?.should be_true
                end
            end
            context 'forms with javacript: in action' do
                it 'returns true' do
                    create_page(
                        body:    '<form action="javascript:doStuff();"></form>',
                        headers: { 'content-type' => 'text/html' }
                    ).has_script?.should be_true
                end
            end
            context 'no client-side code' do
                it 'returns false' do
                    create_page( body: 'stuff' ).has_script?.should be_false
                end
            end
        end
    end

    describe '#text?' do
        context 'when the HTTP response is text/html' do
            it 'returns true' do
                Arachni::Parser.new( Factory[:html_response] ).page.text?.should be_true
            end
        end

        context 'when the response is not text based' do
            it 'returns false' do
                Arachni::Parser.new( Factory[:binary_response] ).page.text?.should be_false
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
                c.should_not == p

                c = p.dup
                c.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.should_not == p

                c = p.dup
                c.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.should_not == p

                c = p.dup
                c.dom.push_transition described_class::DOM::Transition.new( "<a href='#' id='stuff'>", :onhover )
                c.should_not == p
            end
        end
        context 'when the pages are identical' do
            it 'returns true' do
                p = create_page( body: 'stuff here')
                p.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]
                p.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]
                p.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]

                c = p.dup
                c.should == p

                p.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                p.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                p.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                p.dom.push_transition described_class::DOM::Transition.new( "<a href='#' id='stuff'>", :onhover )

                c.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.dom.push_transition described_class::DOM::Transition.new( "<a href='#' id='stuff'>", :onhover )

                c.should == p
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
                c.should_not eql p

                c = p.dup
                c.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.should_not eql p

                c = p.dup
                c.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.should_not eql p
            end
        end
        context 'when the pages are identical' do
            it 'returns true' do
                p = create_page( body: 'stuff here')
                p.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]
                p.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]
                p.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff' } )]

                c = p.dup
                c.should eql p

                c = p.dup
                p.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                p.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                p.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]

                c.links |= [Arachni::Element::Link.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.forms |= [Arachni::Element::Form.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.cookies |= [Arachni::Element::Cookie.new( url: 'http://test.com', inputs: { 'test' => 'stuff2' } )]
                c.should eql p
            end
        end
    end

    describe '#title' do
        context 'when the page has a title' do
            it 'returns the page title' do
                title = 'Stuff here'
                create_page( body: "<title>#{title}</title>" ).title.should == title
                create_page( body: '<title></title>' ).title.should == ''
            end
        end
        context 'when the page does not have a title' do
            it 'returns nil' do
                create_page.title.should be_nil
                create_page( body: '' ).title.should be_nil
            end
        end
    end

    describe '#elements' do
        it 'returns all page elements' do
            page.elements.should == (page.links | page.forms | page.cookies | page.headers)
        end
    end

    describe '#clear_cache' do
        it 'returns self' do
            subject.clear_cache.should == subject
        end

        it 'clears the #cache' do
            cachable = [:query_vars, :links, :forms, :cookies, :headers, :paths,
                        :document, :parser]

            subject.cache.keys.should == [:parser]

            cachable.each do |attribute|
                subject.send attribute
            end

            subject.cache.keys.sort.should == cachable.sort
            subject.clear_cache
            subject.cache.keys.should be_empty
        end

        [:links, :forms, :cookies, :headers].each do |type|
            context "when ##{type} have been externally set" do
                it 'does not empty their cache' do
                    subject.send("#{type}=", subject.send(type))
                    subject.clear_cache
                    subject.cache.keys.should == [type]
                    subject.cache[type].should == subject.send(type)
                end
            end
        end
    end

    describe '#prepare_for_report' do
        it 'calls #clear_cache' do
            s = subject.dup
            s.should receive(:clear_cache)
            s.prepare_for_report
        end

        it 'removes #dom#digest' do
            subject.dom.digest = 'stuff'
            subject.prepare_for_report
            subject.dom.digest.should be_nil
        end

        it 'removes #dom#skip_states' do
            subject.dom.skip_states.should be_true
            subject.prepare_for_report
            subject.dom.digest.should be_nil
        end
    end

    [:dup, :deep_clone].each do |method|
        describe "##{method}" do
            it 'returns a copy of the page' do
                dupped = subject.send(method)
                dupped.should == subject
            end

            [:response, :body, :links, :forms, :cookies, :headers, :cookiejar, :paths].each do |m|
                it "preserves ##{m}" do
                    dupped = subject.send(method)

                    # Make sure we're not comparing nils.
                    subject.send( m ).should be_true

                    # Make sure we're not comparing empty stuff.
                    if (enumerable = dupped.send( m )).is_a? Enumerable
                        enumerable.should be_any
                    end

                    dupped.send( m ).should == subject.send( m )
                end
            end

            it 'preserves #element_audit_whitelist' do
                subject.update_element_audit_whitelist subject.elements.first
                dupped = subject.send(method)
                dupped.element_audit_whitelist.should include subject.elements.first.audit_scope_id
            end


            [:url, :skip_states, :transitions, :data_flow_sink, :execution_flow_sink].each do |m|
                it "preserves #{Arachni::Page::DOM}##{m}" do
                    dupped = subject.send(method)

                    # Make sure we're not comparing nils.
                    subject.dom.send( m ).should be_true

                    # Make sure we're not comparing empty stuff.
                    if (enumerable = dupped.dom.send( m )).is_a? Enumerable
                        enumerable.should be_any
                    end

                    dupped.dom.send( m ).should == subject.dom.send( m )
                end
            end

            it 'preserves Arachni::Element::Form#node of #forms' do
                form = subject.forms.last
                form.node.should be_kind_of Nokogiri::XML::Element
                form.node.should be_true

                subject.send(method).forms.first.node.to_s.should == form.node.to_s
            end

            it 'preserves Arachni::Element::Link#node of #links' do
                link = subject.links.last
                link.node.should be_kind_of Nokogiri::XML::Element
                link.node.should be_true

                subject.send(method).links.last.node.to_s.should == link.node.to_s
            end

            it 'preserves #page associations for #elements' do
                dup = subject.send(method)
                dup.elements.should be_any
                dup.elements.each { |e| e.page.should == subject }
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
                body: 'test',
                paths: [ 'http://test/1', 'http://test/2' ],
                links: [Arachni::Element::Link.new( elem_opts )],
                forms: [Arachni::Element::Form.new( elem_opts )],
                cookies: [Arachni::Element::Cookie.new( elem_opts )],
                cookiejar: [
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
            page.code.should == data[:response][:code]
            page.url.should == data[:url]
            page.body.should == data[:body]
            page.paths.should == data[:paths]

            page.links.should == data[:links]
            page.forms.should == data[:forms]
            page.cookies.should == data[:cookies]
            page.headers.should == data[:headers]

            page.cookiejar.should == data[:cookiejar]

            page.response.code.should == data[:response][:code]
            page.response.url.should == data[:url]
            page.response.body.should == data[:body]
            page.response.request.url.should == data[:url]

            page.dom.url.should == data[:dom][:url]
            page.dom.transitions.should == data[:dom][:transitions]
        end

        context 'when no HTTP data is given' do
            it 'creates them with default values' do
                data = {
                    url:  'http://test/',
                    body: 'test'
                }

                page = Arachni::Page.from_data( data )
                page.url.should == data[:url]
                page.body.should == data[:body]
                page.code.should == 200

                page.links.should == []
                page.forms.should == []
                page.cookies.should == []
                page.headers.should == []

                page.cookiejar.should == []

                page.response.code.should == 200
                page.response.url.should == data[:url]
                page.response.body.should == data[:body]
                page.response.request.url.should == data[:url]
            end
        end
    end

    describe '.from_response' do
        it 'creates a page from an HTTP response' do
            page = Arachni::Page.from_response( response )
            page.class.should == Arachni::Page
            parser = Arachni::Parser.new( response )

            page.url.should == parser.url
            page.method.should == parser.response.request.method
            page.response.should == parser.response
            page.body.should == parser.response.body
            page.query_vars.should == parser.link_vars
            page.paths.should == parser.paths
            page.links.should == parser.links
            page.forms.should == parser.forms
            page.cookies.should == parser.cookies_to_be_audited
            page.headers.should == parser.headers
            page.cookiejar.should == parser.cookie_jar
            page.text?.should == parser.text?

        end
    end

end
