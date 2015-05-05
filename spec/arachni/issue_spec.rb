require 'spec_helper'

describe Arachni::Issue do

    let( :request ) { Factory[:request] }
    let( :response ) { Factory[:response] }
    let( :vector ) { Factory[:vector] }
    let( :passive_vector ) { Factory[:passive_vector] }
    let( :active_vector ) { Factory[:active_vector] }

    let( :issue_data ) { Factory[:issue_data] }
    let( :passive_issue_data ) { Factory[:passive_issue_data] }
    let( :issue ) { Factory[:issue] }
    let( :empty_issue ) { Factory[:issue_empty] }
    let( :passive_issue ) { Factory[:passive_issue] }
    let( :active_issue ) { Factory[:active_issue] }
    let( :trusted_issue ) { Factory[:trusted_issue] }
    let( :untrusted_issue ) { Factory[:untrusted_issue] }
    let( :issue_with_variations ) { Factory[:issue_with_variations] }

    it "supports #{Arachni::RPC::Serializer}" do
        duped = Arachni::RPC::Serializer.deep_clone( issue_with_variations )
        issue_with_variations.should == duped

        duped.variations.should == issue_with_variations.variations
    end

    it 'recodes string data to UTF8' do
        issue.name.should == "Check name \u2713"
    end

    describe '#recheck' do
        it 'rechecks the issue' do
            Arachni::Options.paths.checks = fixtures_path + '/taint_check/'
            Arachni::Options.audit.elements :links, :forms, :cookies

            issue = nil
            Arachni::Framework.new do |f|
                f.options.url = "#{web_server_url_for( :auditor )}/link"
                f.checks.load :taint

                f.run
                issue = f.report.issues.first.variations.first
            end

            issue.recheck.should == issue
        end
    end

    describe '#to_rpc_data' do
        let(:issue) { issue_with_variations }
        let(:data) { issue.to_rpc_data }

        %w(name description platform_name platform_type references cwe
            remedy_guidance remedy_code tags trusted unique_id digest
            digest).each do |attribute|
            it "includes '#{attribute}'" do
                data[attribute].should == issue.send( attribute )
            end
        end

        it "includes 'variations'" do
            check = issue.check.dup
            data['check'].should == check.merge(elements: check[:elements].map(&:to_s))
        end

        it "includes 'variations'" do
            data['variations'].should == issue.variations.map(&:to_rpc_data)
        end

        it "includes 'vector'" do
            data['vector'].should == issue.vector.to_rpc_data
        end

        it "includes 'severity'" do
            data['severity'].should == issue.severity.to_s
        end

        it "includes 'variation'" do
            data['variation'].should == issue.variation?
        end
    end

    describe '.from_rpc_data' do
        let(:issue) { issue_with_variations }
        let(:restored_issue) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( issue ) }

        %w(name description vector platform_name platform_type references cwe
            remedy_guidance remedy_code tags check trusted variations unique_id
            digest digest severity).each do |attribute|
            it "restores '#{attribute}'" do
                restored_issue.send( attribute ).should == issue.send( attribute )
            end
        end

        it "restores 'variation'" do
            restored_issue.variation?.should == issue.variation?
        end

        it 'restores variation parent' do
            restored_issue.variations.each do |v|
                v.parent.should == restored_issue
            end
        end
    end

    [:page=, :referring_page=, :vector=].each do |m|
        describe "##{m}" do
            let(:obj) do
                obj = Object.new
                obj.stub(:deep_clone).and_return(obj)
                obj.stub(:prepare_for_report)
                obj
            end

            it 'calls #deep_clone' do
                obj.should receive(:deep_clone)
                empty_issue.send( "#{m}", obj )
            end
            it 'calls #prepare_for_report' do
                obj.should receive(:prepare_for_report)
                empty_issue.send( "#{m}", obj )
            end
        end
    end

    describe '#tags' do
        it 'returns the set tags' do
            issue.tags.should == issue_data[:tags]
        end
        context 'when nil' do
            it 'defaults to an empty array' do
                empty_issue.tags.should == []
            end
        end
    end

    describe '#active?' do
        context 'when the issue was discovered by manipulating an input' do
            it 'returns true' do
                active_issue.active?.should be_true
            end
        end
        context 'when the issue was logged passively' do
            it 'returns false' do
                passive_issue.active?.should be_false
            end
        end
        context 'when the issue has active variations' do
            it 'returns true' do
                issue_with_variations.active?.should be_true
            end
        end
    end

    describe '#passive?' do
        context 'when the issue was discovered by manipulating an input' do
            it 'returns false' do
                passive_issue.passive?.should be_true
            end
        end
        context 'when the issue was logged passively' do
            it 'returns true' do
                passive_issue.passive?.should be_true
            end
        end
    end

    describe '#trusted?' do
        context 'when the issue is not trusted' do
            it 'returns false' do
                untrusted_issue.trusted?.should be_false
            end
        end
        context 'when the issue does is trusted' do
            it 'returns true' do
                trusted_issue.trusted?.should be_true
            end
        end
        context 'by default' do
            it 'returns true' do
                trusted_issue.trusted?.should be_true
            end
        end
    end

    describe '#untrusted?' do
        context 'when the issue is not trusted' do
            it 'returns true' do
                untrusted_issue.untrusted?.should be_true
            end
        end
        context 'when the issue is trusted' do
            it 'returns false' do
                trusted_issue.untrusted?.should be_false
            end
        end
        context 'by default' do
            it 'returns false' do
                issue.untrusted?.should be_false
            end
        end
    end

    describe '#affected_input_name' do
        context 'when the issue is' do
            context 'active' do
                it 'returns the name of the affected input' do
                    active_issue.affected_input_name.should ==
                        active_issue.vector.affected_input_name
                end
            end

            context 'passive' do
                it 'returns nil' do
                    passive_issue.affected_input_name.should be_nil
                end
            end
        end

    end

    describe '#cwe=' do
        it 'assigns a CWE ID and CWE URL based on that ID' do
            empty_issue.cwe = 20
            empty_issue.cwe.should == 20
        end
    end

    describe '#cwe_url' do
        it 'returns the CWE reference URL' do
            described_class.new( vector: vector, cwe: 21 ).cwe_url.should ==
                'http://cwe.mitre.org/data/definitions/21.html'
        end

        context 'when no #cwe has been given' do
            it 'returns nil' do
                described_class.new( vector: vector, cwe: nil ).cwe_url.should be_nil
            end
        end
    end

    describe '#signature=' do
        it 'assigns a signature as a String' do
            signature = /test.*/

            empty_issue.signature = signature
            empty_issue.signature.should == signature.to_s
        end

        context 'when no signature has been given' do
            it 'returns nil' do
                empty_issue.signature = nil
                empty_issue.signature.should be_nil
            end
        end
    end

    describe '#references=' do
        it 'assigns a references hash' do
            refs = { 'title' => 'url' }
            empty_issue.references = refs
            empty_issue.references.should == refs
        end
        context 'when nil is passed as a value' do
            it 'falls-back to an empty Hash' do
                empty_issue.references.should == {}
                empty_issue.references = nil
                empty_issue.references.should == {}
            end
        end
    end

    describe '#remarks' do
        it 'returns the set remarks as a Hash' do
            issue.remarks.should == issue_data[:remarks]
        end
        context 'when uninitialised' do
            it 'falls-back to an empty Hash' do
                empty_issue.remarks.should == {}
            end
        end
    end

    describe '#add_remark' do
        it 'adds a remark' do
            author  = :dude
            remarks = ['Hey dude!', 'Hey again dude!' ]

            empty_issue.add_remark author, remarks.first
            empty_issue.add_remark author, remarks[1]
            empty_issue.remarks.should == { author => remarks }
        end

        context 'when an argument is blank' do
            it 'raises an ArgumentError' do
                raised = false
                begin
                    empty_issue.add_remark '', 'ddd'
                rescue ArgumentError
                    raised = true
                end
                raised.should be_true

                raised = false
                begin
                    empty_issue.add_remark :dsds, ''
                rescue ArgumentError
                    raised = true
                end
                raised.should be_true

                raised = false
                begin
                    empty_issue.add_remark '', ''
                rescue ArgumentError
                    raised = true
                end
                raised.should be_true

                raised = false
                begin
                    empty_issue.add_remark nil, nil
                rescue ArgumentError
                    raised = true
                end
                raised.should be_true
            end
        end
    end

    describe '#to_h' do
        it 'converts self to a Hash' do
            page = Factory[:page].dup
            page.body = "#{page.body}stuff"

            issue.referring_page = page
            issue_h = issue.to_h

            dom_h = issue.page.dom.to_h
            dom_h.delete(:skip_states)
            dom_h[:transitions] = dom_h[:transitions].map do |t|
                h = t.to_hash
                h.delete(:time)
                h
            end

            referring_page_dom_h = issue.referring_page.dom.to_h
            referring_page_dom_h.delete(:skip_states)
            referring_page_dom_h[:transitions] =
                referring_page_dom_h[:transitions].map do |t|
                    h = t.to_hash
                    h.delete(:time)
                    h
                end

            issue_h[:page][:dom][:transitions] =
                issue_h[:page][:dom][:transitions].map do |h|
                    h.delete(:time)
                    h
                end
            issue_h[:page][:dom][:data_flow_sinks] =
                issue_h[:page][:dom][:data_flow_sinks].map(&:to_h)
            issue_h[:page][:dom][:execution_flow_sinks] =
                issue_h[:page][:dom][:execution_flow_sinks].map(&:to_h)

            issue_h[:referring_page][:dom][:transitions] =
                issue_h[:page][:dom][:transitions].map do |h|
                    h.delete(:time)
                    h
                end
            issue_h[:referring_page][:dom][:data_flow_sinks] =
                issue_h[:referring_page][:dom][:data_flow_sinks].map(&:to_h)
            issue_h[:referring_page][:dom][:execution_flow_sinks] =
                issue_h[:referring_page][:dom][:execution_flow_sinks].map(&:to_h)

            issue_h.should == {
                name:            "Check name \u2713",
                description:     'Issue description',
                vector:          issue.vector.to_h,
                referring_page:  {
                    body: issue.referring_page.body,
                    dom:  referring_page_dom_h
                },
                page:            {
                    body: issue.page.body,
                    dom:  dom_h
                },
                response:        Factory[:response].to_h,
                platform_name:   :unix,
                platform_type:   :os,
                references:      { 'Title' => 'http://some/url' },
                severity:        :high,
                remedy_guidance: 'How to fix the issue.',
                remedy_code:     'Sample code on how to fix the issue',
                tags:            %w(these are a few tags),
                remarks:         { the_dude: %w(Hey!) },
                signature:       '(?-mix:some regexp)',
                proof:           "string matched by '/some regexp/'",
                check:           {
                    name:        'Test check',
                    description: 'Test description',
                    author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
                    version:     '0.1',
                    targets:     {
                        'Generic' => 'all'
                    },
                    elements:    [:link, :form_dom],
                    shortname:   'test'
                },
                trusted:         true,
                digest:          3311937213,
                request:         issue.request.to_h,
                cwe:             1,
                variations:      [],
                cwe_url:         'http://cwe.mitre.org/data/definitions/1.html'
            }
        end

        context 'when the issue has variations' do
            it 'includes those variations' do
                page = Factory[:page].dup
                page.body = "#{page.body}stuff"

                issue_with_variations.variations.each { |v| v.referring_page = page }

                issue_h    = issue_with_variations.to_h
                variations = issue_h.delete( :variations )

                issue_h.should == {
                    name:            "Check name \u2713",
                    description:     'Issue description',
                    platform_name:   :unix,
                    platform_type:   :os,
                    references:      { 'Title' => 'http://some/url' },
                    severity:        :high,
                    remedy_guidance: 'How to fix the issue.',
                    remedy_code:     'Sample code on how to fix the issue',
                    tags:            %w(these are a few tags),
                    check:           {
                        name:        'Test check',
                        description: 'Test description',
                        author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
                        version:     '0.1',
                        targets:     {
                            'Generic' => 'all'
                        },
                        elements:    [:link, :form_dom],
                        shortname:   'test'
                    },
                    digest:          58999149,
                    cwe:             1,
                    variation:       false,
                    trusted:         true,
                    vector:          {
                        method: :get,
                        type:   :form,
                        class:   'Arachni::Element::Form',
                        url:    'http://test.com/',
                        action: 'http://test.com/',
                        inputs:  { 'stuff' => '1' },
                        affected_input_name:  'stuff',
                        source: nil
                    },
                    cwe_url:         'http://cwe.mitre.org/data/definitions/1.html'
                }

                variations.each_with_index do |variation, i|
                    dom_h = issue.page.dom.to_h
                    dom_h.delete(:skip_states)
                    dom_h[:transitions] = dom_h[:transitions].map do |t|
                        h = t.to_hash
                        h.delete(:time)
                        h
                    end

                    referring_page_dom_h = variation[:referring_page][:dom]
                    referring_page_dom_h.delete(:skip_states)
                    referring_page_dom_h[:transitions] =
                        referring_page_dom_h[:transitions].map do |t|
                            h = t.to_hash
                            h.delete(:time)
                            h
                        end


                    variation[:page][:dom][:transitions] =
                        variation[:page][:dom][:transitions].map do |h|
                            h.delete(:time)
                            h
                        end
                    variation[:page][:dom][:data_flow_sinks] =
                        variation[:page][:dom][:data_flow_sinks].map(&:to_h)
                    variation[:page][:dom][:execution_flow_sinks] =
                        variation[:page][:dom][:execution_flow_sinks].map(&:to_h)

                    variation[:referring_page][:dom][:transitions] =
                        variation[:page][:dom][:transitions].map do |h|
                            h.delete(:time)
                            h
                        end
                    variation[:referring_page][:dom][:data_flow_sinks] =
                        variation[:referring_page][:dom][:data_flow_sinks].map(&:to_h)
                    variation[:referring_page][:dom][:execution_flow_sinks] =
                        variation[:referring_page][:dom][:execution_flow_sinks].map(&:to_h)

                    variation.should == {
                        vector:    {
                            method:               :get,
                            inputs:               { 'stuff' => i.to_s },
                            affected_input_value: i.to_s,
                            seed:                 i.to_s,
                            class:                Arachni::Element::Form.to_s,
                        },
                        referring_page:  {
                            body: page.body,
                            dom:  referring_page_dom_h
                        },
                        page:            {
                            body: issue.page.body,
                            dom:  dom_h
                        },
                        response:  issue.response.to_h,
                        remarks:   { the_dude: %w(Hey!) },
                        signature: '(?-mix:some regexp)',
                        proof:     "string matched by '/some regexp/'",
                        trusted:   true,
                        request:   issue.request.to_h,
                        variation: true
                    }
                end
            end
        end
    end

    describe '#unique_id' do
        it 'returns a string uniquely identifying the issue' do
            i = active_issue
            i.unique_id.should ==
                "#{i.name}:#{i.vector.method}:#{i.vector.affected_input_name}:#{i.vector.url}"

            i = passive_issue
            i.unique_id.should == "#{i.name}:#{i.vector.url}"
        end
    end

    describe '#eql?' do
        context 'when 2 issues are equal' do
            it 'returns true' do
                issue.eql?( issue ).should be_true
            end
        end
        context 'when 2 issues are not equal' do
            it 'returns false' do
                i = issue.deep_clone
                i.name = 'stuff'
                issue.eql?( i ).should be_false

                i = issue.deep_clone
                i.vector.action = 'http://stuff'
                issue.eql?( i ).should be_false

                i = issue.deep_clone
                i.vector.affected_input_name = 'Stuff'
                issue.eql?( i ).should be_false
            end

            context 'when the issue is' do
                context 'active' do
                    it 'takes into account the vector method' do
                        i = active_issue.deep_clone
                        i.vector.method = :post
                        active_issue.eql?( i ).should be_false
                    end
                end
                context 'passive' do
                    it 'does not take into account the vector method' do
                        i = issue.deep_clone
                        i.vector.method = :post
                        issue.eql?( i ).should be_true
                    end
                end
            end
        end
    end

    describe '#with_variations' do
        it 'returns a copy of the issue with variation data removed' do
            variation_data = [ :response, :proof, :signature, :remarks ]

            variation_data.each do |k|
                issue.send(k).should be_true
            end

            root = issue.with_variations
            variation_data.each do |k|
                root.send(k).should be_nil
            end
            root.variations.should == []
        end

        it 'removes specific issue data from the vector' do
            vector = active_issue.vector
            vector.affected_input_name.should be_true
            vector.affected_input_value.should be_true
            vector.seed.should be_true

            vector = active_issue.with_variations.vector
            vector.affected_input_name.should be_nil
            vector.affected_input_value.should be_nil
            vector.seed.should be_nil
        end
    end

    describe '#as_variation' do
        it 'returns a copy of the issue with generic data removed' do
            variation_data = [
                :name, :description, :platform_name, :platform_type, :references,
                :cwe, :severity, :remedy_guidance, :remedy_code, :tags, :check,
                :cwe_url
            ]

            variation_data.each do |k|
                issue.send(k).should be_true
            end

            root = issue.as_variation
            variation_data.each do |k|
                root.send(k).should be_nil
            end
            root.variations.should be_nil
        end

        it 'has a #parent' do
            issue.as_variation.parent.should == issue
        end
    end

    describe '#to_solo!' do
        it 'converts a variation to a solo issue in place, using a parent as a reference' do
            original_solo  = issue
            parent         = issue.with_variations
            variation      = issue.as_variation

            original_solo.should be_solo
            parent.should_not    be_variation
            variation.should     be_variation

            solo = variation.to_solo!( parent )
            solo.should be_solo

            solo.to_h.should == original_solo.to_h
            solo.to_h.should == variation.to_h
            solo.object_id.should == variation.object_id
        end

        it 'skips #variations' do
            parent    = issue.with_variations
            variation = issue.as_variation

            parent.variations << variation

            parent.variations.should be_any
            variation.to_solo!( parent ).variations.should be_empty
        end

        it 'skips #vector' do
            parent    = active_issue.with_variations
            variation = active_issue.as_variation

            parent.vector.affected_input_name.should be_nil
            variation.vector.affected_input_name.should be_true
            variation.to_solo!( parent ).vector.affected_input_name.should be_true
        end

        it 'skips #parent' do
            parent    = issue.with_variations
            variation = issue.as_variation

            variation.to_solo!( parent ).parent.should be_nil
        end
    end

    describe '#to_solo' do
        it 'returns a solo issue using a parent as a reference' do
            original_solo  = issue
            parent         = issue.with_variations
            variation      = issue.as_variation

            original_solo.should be_solo
            parent.should_not    be_variation
            variation.should     be_variation

            solo = variation.to_solo( parent )
            solo.should be_solo

            solo.to_h.should == original_solo.to_h
            solo.object_id.should_not == variation.object_id
        end
    end

    describe '#variation?' do
        context 'when the issue is' do
            context 'variation' do
                it 'returns true' do
                    issue.as_variation.should be_variation
                end
            end

            context 'parent' do
                it 'returns false' do
                    issue.with_variations.should_not be_variation
                end
            end

            context 'solo' do
                it 'returns false' do
                    issue.should_not be_variation
                end
            end
        end
    end

    describe '#solo?' do
        context 'when the issue is' do
            context 'variation' do
                it 'returns false' do
                    issue.as_variation.should_not be_solo
                end
            end

            context 'parent' do
                it 'returns false' do
                    issue.with_variations.should_not be_solo
                end
            end

            context 'solo' do
                it 'returns true' do
                    issue.should be_solo
                end
            end
        end
    end

    describe '#hash' do
        context 'when 2 issues are equal' do
            it 'have the same hash' do
                issue.hash.should == issue.hash
            end
        end
        context 'when 2 issues are not equal' do
            it 'returns false' do
                i = issue.deep_clone
                i.name = 'stuff'
                issue.hash.should_not == i.hash

                i = issue.deep_clone
                i.vector.action = 'http://stuff'
                issue.hash.should_not == i.hash

                i = issue.deep_clone
                i.vector.affected_input_name = 'Stuff'
                issue.hash.should_not == i.hash
            end
        end
    end

    describe '#digest' do
        it 'returns a Integer hash based on #unique_id' do
            issue.digest.should be_kind_of Integer
            issue.digest.should == issue.unique_id.persistent_hash
        end
    end

end
