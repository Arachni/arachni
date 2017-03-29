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

    it "supports #{Arachni::RPC::Serializer}" do
        duped = Arachni::RPC::Serializer.deep_clone( issue )
        expect(issue).to eq(duped)
    end

    it 'recodes string data to UTF8' do
        expect(issue.name).to eq("Check name \u2713")
    end

    it 'is comparable' do
        informational = issue.dup.tap { |i| i.severity = Arachni::Issue::Severity::INFORMATIONAL }
        low           = issue.dup.tap { |i| i.severity = Arachni::Issue::Severity::LOW }
        medium        = issue.dup.tap { |i| i.severity = Arachni::Issue::Severity::MEDIUM }
        high          = issue.dup.tap { |i| i.severity = Arachni::Issue::Severity::HIGH }

        expect(informational).to be < low
        expect(low).to be < medium
        expect(medium).to be < high

        expect(high).to be > medium
        expect(medium).to be > low
        expect(low).to be > informational

        expect([low, informational, high, medium].sort).to eq(
            [informational, low, medium, high]
        )
    end

    describe '#recheck' do
        it 'rechecks the issue' do
            Arachni::Options.paths.checks = fixtures_path + '/signature_check/'
            Arachni::Options.audit.elements :links, :forms, :cookies

            issue = nil
            Arachni::Framework.new do |f|
                f.options.url = "#{web_server_url_for( :auditor )}/link"
                f.checks.load :signature

                f.run
                issue = f.report.issues.first
            end

            expect(issue.recheck).to eq(issue)
        end
    end

    describe '#to_rpc_data' do
        let(:data) { issue.to_rpc_data }

        %w(name description platform_name platform_type references cwe
            remedy_guidance remedy_code tags trusted unique_id digest
            digest).each do |attribute|
            it "includes '#{attribute}'" do
                expect(data[attribute]).to eq(issue.send( attribute ))
            end
        end

        it "includes 'check'" do
            check = issue.check.dup
            expect(data['check']).to eq(check.merge(elements: check[:elements].map(&:to_s)))
        end

        it "includes 'vector'" do
            expect(data['vector']).to eq(issue.vector.to_rpc_data)
        end

        it "includes 'severity'" do
            expect(data['severity']).to eq(issue.severity.to_s)
        end
    end

    describe '.from_rpc_data' do
        let(:restored_issue) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( issue ) }

        %w(name description vector platform_name platform_type references cwe
            remedy_guidance remedy_code tags check trusted unique_id
            digest digest severity).each do |attribute|
            it "restores '#{attribute}'" do
                expect(restored_issue.send( attribute )).to eq(issue.send( attribute ))
            end
        end
    end

    [:page=, :referring_page=, :vector=].each do |m|
        describe "##{m}" do
            let(:obj) do
                Factory[{ :page= => :page, :referring_page= => :page, :vector= => :vector }[m]]
            end

            it 'clones the object' do
                expect(obj).to receive(:rpc_clone).and_return(obj.rpc_clone)
                empty_issue.send( "#{m}", obj )
            end

            it 'calls #prepare_for_report' do
                expect(obj).to receive(:rpc_clone).and_return(obj)
                expect(obj).to receive(:prepare_for_report)

                empty_issue.send( "#{m}", obj )
            end
        end
    end

    describe '#tags' do
        it 'returns the set tags' do
            expect(issue.tags).to eq(issue_data[:tags])
        end
        context 'when nil' do
            it 'defaults to an empty array' do
                expect(empty_issue.tags).to eq([])
            end
        end
    end

    describe '#active?' do
        context 'when the issue was discovered by manipulating an input' do
            it 'returns true' do
                expect(active_issue.active?).to be_truthy
            end
        end
        context 'when the issue was logged passively' do
            it 'returns false' do
                expect(passive_issue.active?).to be_falsey
            end
        end
    end

    describe '#passive?' do
        context 'when the issue was discovered by manipulating an input' do
            it 'returns false' do
                expect(passive_issue.passive?).to be_truthy
            end
        end
        context 'when the issue was logged passively' do
            it 'returns true' do
                expect(passive_issue.passive?).to be_truthy
            end
        end
    end

    describe '#trusted?' do
        context 'when the issue is not trusted' do
            it 'returns false' do
                expect(untrusted_issue.trusted?).to be_falsey
            end
        end
        context 'when the issue does is trusted' do
            it 'returns true' do
                expect(trusted_issue.trusted?).to be_truthy
            end
        end
        context 'by default' do
            it 'returns true' do
                expect(trusted_issue.trusted?).to be_truthy
            end
        end
    end

    describe '#untrusted?' do
        context 'when the issue is not trusted' do
            it 'returns true' do
                expect(untrusted_issue.untrusted?).to be_truthy
            end
        end
        context 'when the issue is trusted' do
            it 'returns false' do
                expect(trusted_issue.untrusted?).to be_falsey
            end
        end
        context 'by default' do
            it 'returns false' do
                expect(issue.untrusted?).to be_falsey
            end
        end
    end

    describe '#affected_input_name' do
        context 'when the issue is' do
            context 'active' do
                it 'returns the name of the affected input' do
                    expect(active_issue.affected_input_name).to eq(
                        active_issue.vector.affected_input_name
                    )
                end
            end

            context 'passive' do
                it 'returns nil' do
                    expect(passive_issue.affected_input_name).to be_nil
                end
            end
        end

    end

    describe '#cwe=' do
        it 'assigns a CWE ID and CWE URL based on that ID' do
            empty_issue.cwe = 20
            expect(empty_issue.cwe).to eq(20)
        end
    end

    describe '#cwe_url' do
        it 'returns the CWE reference URL' do
            expect(described_class.new( vector: vector, cwe: 21 ).cwe_url).to eq(
                'http://cwe.mitre.org/data/definitions/21.html'
            )
        end

        context 'when no #cwe has been given' do
            it 'returns nil' do
                expect(described_class.new( vector: vector, cwe: nil ).cwe_url).to be_nil
            end
        end
    end

    describe '#signature=' do
        context 'when it is a Regexp' do
            it 'stores the source' do
                signature = /test.*/

                empty_issue.signature = signature
                expect(empty_issue.signature).to eq(signature.source)
            end
        end

        context 'when it is a String' do
            it 'stores it' do
                signature = 'stuff'

                empty_issue.signature = signature
                expect(empty_issue.signature).to eq(signature)
            end
        end

        context 'when no signature has been given' do
            it 'returns nil' do
                empty_issue.signature = nil
                expect(empty_issue.signature).to be_nil
            end
        end
    end

    describe '#references=' do
        it 'assigns a references hash' do
            refs = { 'title' => 'url' }
            empty_issue.references = refs
            expect(empty_issue.references).to eq(refs)
        end
        context 'when nil is passed as a value' do
            it 'falls-back to an empty Hash' do
                expect(empty_issue.references).to eq({})
                empty_issue.references = nil
                expect(empty_issue.references).to eq({})
            end
        end
    end

    describe '#remarks' do
        it 'returns the set remarks as a Hash' do
            expect(issue.remarks).to eq(issue_data[:remarks])
        end
        context 'when uninitialised' do
            it 'falls-back to an empty Hash' do
                expect(empty_issue.remarks).to eq({})
            end
        end
    end

    describe '#add_remark' do
        it 'adds a remark' do
            author  = :dude
            remarks = ['Hey dude!', 'Hey again dude!' ]

            empty_issue.add_remark author, remarks.first
            empty_issue.add_remark author, remarks[1]
            expect(empty_issue.remarks).to eq({ author => remarks })
        end

        context 'when an argument is blank' do
            it 'raises an ArgumentError' do
                raised = false
                begin
                    empty_issue.add_remark '', 'ddd'
                rescue ArgumentError
                    raised = true
                end
                expect(raised).to be_truthy

                raised = false
                begin
                    empty_issue.add_remark :dsds, ''
                rescue ArgumentError
                    raised = true
                end
                expect(raised).to be_truthy

                raised = false
                begin
                    empty_issue.add_remark '', ''
                rescue ArgumentError
                    raised = true
                end
                expect(raised).to be_truthy

                raised = false
                begin
                    empty_issue.add_remark nil, nil
                rescue ArgumentError
                    raised = true
                end
                expect(raised).to be_truthy
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

            expect(issue_h).to eq({
                name:            "Check name \u2713",
                description:     'Issue description',
                vector:          issue.vector.to_h.merge(
                                     affected_input_name: issue.affected_input_name
                                 ),
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
                signature:       'some regexp',
                proof:           "string matched by '/some regexp/'",
                check:           {
                    name:        'Test check',
                    description: 'Test description',
                    author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com> ',
                    version:     '0.1',
                    targets:     {
                        'Generic' => 'all'
                    },
                    elements:    [:link],
                    shortname:   'test'
                },
                trusted:         true,
                digest:          issue.digest,
                request:         issue.request.to_h,
                cwe:             1,
                cwe_url:         'http://cwe.mitre.org/data/definitions/1.html'
            })
        end
    end

    describe '#unique_id' do
        it 'returns a string uniquely identifying the issue' do
            i = active_issue
            expect(i.unique_id).to eq(
                "#{i.name}:#{i.vector.method}:#{i.vector.affected_input_name}:#{i.vector.url}"
            )

            i = passive_issue
            expect(i.unique_id).to eq("#{i.name}:#{i.proof}:#{i.vector.affected_input_name}:#{i.vector.url}")
        end
    end

    describe '#eql?' do
        context 'when 2 issues are equal' do
            it 'returns true' do
                expect(issue.eql?( issue )).to be_truthy
            end
        end
        context 'when 2 issues are not equal' do
            it 'returns false' do
                i = issue.deep_clone
                i.name = 'stuff'
                expect(issue.eql?( i )).to be_falsey

                i = issue.deep_clone
                i.vector.action = 'http://stuff'
                expect(issue.eql?( i )).to be_falsey

                i = issue.deep_clone
                i.vector.affected_input_name = 'Stuff'
                expect(issue.eql?( i )).to be_falsey
            end

            context 'when the issue is' do
                context 'active' do
                    it 'takes into account the vector method' do
                        i = active_issue.deep_clone
                        i.vector.method = :post
                        expect(active_issue.eql?( i )).to be_falsey
                    end
                end
                context 'passive' do
                    it 'does not take into account the vector method' do
                        i = issue.deep_clone
                        i.vector.method = :post
                        expect(issue.eql?( i )).to be_truthy
                    end
                end
            end
        end
    end

    describe '#hash' do
        context 'when 2 issues are equal' do
            it 'have the same hash' do
                expect(issue.hash).to eq(issue.hash)
            end
        end
        context 'when 2 issues are not equal' do
            it 'returns false' do
                i = issue.deep_clone
                i.name = 'stuff'
                expect(issue.hash).not_to eq(i.hash)

                i = issue.deep_clone
                i.vector.action = 'http://stuff'
                expect(issue.hash).not_to eq(i.hash)

                i = issue.deep_clone
                i.vector.affected_input_name = 'Stuff'
                expect(issue.hash).not_to eq(i.hash)
            end
        end
    end

    describe '#digest' do
        it 'returns a Integer hash based on #unique_id' do
            expect(issue.digest).to be_kind_of Integer
            expect(issue.digest).to eq(issue.unique_id.persistent_hash)
        end
    end

end
