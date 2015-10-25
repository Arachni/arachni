require 'spec_helper'

describe Arachni::OptionGroups::Audit do
    include_examples 'option_group'
    subject { described_class.new }

    %w(with_both_http_methods exclude_vector_patterns include_vector_patterns
        links forms cookies cookies_extensively headers link_templates with_raw_payloads
    ).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end

    describe '#link_templates=' do
        it 'converts its param to an Array of Regexp' do
            templates = %w(/param\/(?<param>\w+)/ /param2\/(?<param2>\w+)/)

            subject.link_templates = templates.first
            expect(subject.link_templates).to eq([Regexp.new( templates.first, Regexp::IGNORECASE )])

            subject.link_templates = templates
            expect(subject.link_templates).to eq(templates.map { |p| Regexp.new( p, Regexp::IGNORECASE ) })
        end

        context 'when given nil' do
            it 'empties the templates' do
                subject.link_templates = /param\/(?<param>\w+)/
                expect(subject.link_templates).to be_any
                subject.link_templates = nil
                expect(subject.link_templates).to be_empty
            end
        end

        context 'when given false' do
            it 'empties the templates' do
                subject.link_templates = /param\/(?<param>\w+)/
                expect(subject.link_templates).to be_any
                subject.link_templates = false
                expect(subject.link_templates).to be_empty
            end
        end

        context 'when given an invalid template' do
            it "raises #{described_class::Error::InvalidLinkTemplate}" do
                expect { subject.link_templates = /(.*)/ }.to raise_error
                described_class::Error::InvalidLinkTemplate
            end
        end
    end

    describe '#with_raw_payloads?' do
        context 'when #with_raw_payloads is' do
            it 'true' do
                subject.with_raw_payloads = true
                expect(subject.with_raw_payloads?).to eq(true)
            end
        end

        context 'when #with_raw_payloads is' do
            it 'returns false' do
                subject.with_raw_payloads = false
                expect(subject.with_raw_payloads?).to eq(false)
            end
        end
    end

    describe '#link_templates?' do
        context 'when templates are available' do
            it 'returns true' do
                subject.link_templates << /param\/(?<param>\w+)/
                expect(subject.link_templates?).to eq(true)
            end
        end

        context 'when templates not available' do
            it 'returns false' do
                expect(subject.link_templates?).to eq(false)
            end
        end
    end

    [:links, :forms, :cookies, :headers, :cookies_extensively,
     :with_both_http_methods, :link_doms, :form_doms, :cookie_doms].each do |attribute|
        describe "#{attribute}?" do
            context "when ##{attribute} is" do
                context 'true' do
                    it 'returns true' do
                        subject.send "#{attribute}=", true
                        expect(subject.send("#{attribute}?")).to eq(true)
                    end
                end

                context 'false' do
                    it 'returns false' do
                        subject.send "#{attribute}=", false
                        expect(subject.send("#{attribute}?")).to eq(false)
                    end
                end

                context 'nil' do
                    it 'returns false' do
                        subject.send "#{attribute}=", false
                        expect(subject.send("#{attribute}?")).to eq(false)
                    end
                end
            end
        end
    end

    describe '#exclude_vector_patterns=' do
        it 'converts the argument to a flat array of Regexp' do
            subject.exclude_vector_patterns = [ [:test], 'string' ]
            expect(subject.exclude_vector_patterns).to eq([/test/i, /string/i])
        end
    end

    describe '#include_vector_patterns=' do
        it 'converts the argument to a flat array of Regexp' do
            subject.include_vector_patterns = [ [:test], 'string' ]
            expect(subject.include_vector_patterns).to eq([/test/i, /string/i])
        end
    end

    describe '#vector?' do
        context 'when #include_vector_patterns' do
            context 'is empty' do
                it 'returns true' do
                    expect(subject.vector?( 'blah' )).to be_truthy
                end
            end

            context 'match the given input name' do
                it 'returns true' do
                    subject.include_vector_patterns = [/stuff/, /blah/]

                    expect(subject.vector?( 'stufferson' )).to be_truthy
                    expect(subject.vector?( 'blaherson' )).to be_truthy
                end
            end

            context 'do not match the given input name' do
                it 'returns false' do
                    subject.include_vector_patterns = [/stuff/, /blah/]

                    expect(subject.vector?( 'mooh' )).to be_falsey
                end
            end
        end

        context 'when #exclude_vector_patterns' do
            context 'is empty' do
                it 'returns true' do
                    expect(subject.vector?( 'blah' )).to be_truthy
                end
            end

            context 'match the given input name' do
                it 'returns true' do
                    subject.exclude_vector_patterns = [/stuff/, /blah/]

                    expect(subject.vector?( 'stufferson' )).to be_falsey
                    expect(subject.vector?( 'blaherson' )).to be_falsey
                end
            end

            context 'do not match the given input name' do
                it 'returns false' do
                    subject.exclude_vector_patterns = [/stuff/, /blah/]

                    expect(subject.vector?( 'mooh' )).to be_truthy
                end
            end
        end
    end

    describe '#elements' do
        it 'enables auditing of the given element types' do
            expect(subject.links).to be_falsey
            expect(subject.forms).to be_falsey
            expect(subject.cookies).to be_falsey
            expect(subject.headers).to be_falsey

            subject.elements :links, :forms, :cookies, :headers

            expect(subject.links).to be_truthy
            expect(subject.forms).to be_truthy
            expect(subject.cookies).to be_truthy
            expect(subject.headers).to be_truthy
        end

        context 'when given an invalid element type' do
            it "raises #{described_class::Error::InvalidElementType}" do
                expect do
                    subject.elements :stuff
                end.to raise_error described_class::Error::InvalidElementType
            end
        end
    end

    describe '#elements=' do
        it 'enables auditing of the given element types' do
            expect(subject.links).to be_falsey
            expect(subject.forms).to be_falsey
            expect(subject.cookies).to be_falsey
            expect(subject.headers).to be_falsey

            subject.elements = :links, :forms, :cookies, :headers

            expect(subject.links).to be_truthy
            expect(subject.forms).to be_truthy
            expect(subject.cookies).to be_truthy
            expect(subject.headers).to be_truthy
        end

        context 'when given an invalid element type' do
            it "raises #{described_class::Error::InvalidElementType}" do
                expect do
                    subject.elements = :stuff
                end.to raise_error described_class::Error::InvalidElementType
            end
        end
    end

    describe '#skip_elements' do
        it 'enables auditing of the given element types' do
            subject.elements :links, :forms, :cookies, :headers
            subject.link_templates = /param\/(?<param>\w+)/

            expect(subject.links?).to be_truthy
            expect(subject.forms?).to be_truthy
            expect(subject.cookies?).to be_truthy
            expect(subject.headers?).to be_truthy
            expect(subject.link_templates?).to be_truthy

            subject.skip_elements :links, :forms, :cookies, :headers, :link_templates

            expect(subject.links?).to be_falsey
            expect(subject.forms?).to be_falsey
            expect(subject.cookies?).to be_falsey
            expect(subject.headers?).to be_falsey
            expect(subject.link_templates?).to be_falsey
        end

        context 'when given an invalid element type' do
            it "raises #{described_class::Error::InvalidElementType}" do
                expect do
                    subject.skip_elements :stuff
                end.to raise_error described_class::Error::InvalidElementType
            end
        end
    end

    describe '#elements?' do
        context 'if the given element is to be audited' do
            it 'returns true' do
                subject.elements :links, :forms, :cookies, :headers
                subject.link_templates << /param\/(?<param>\w+)/

                expect(subject.links).to be_truthy
                expect(subject.elements?( :links )).to be_truthy
                expect(subject.elements?( :link )).to be_truthy
                expect(subject.elements?( 'links' )).to be_truthy
                expect(subject.elements?( 'link' )).to be_truthy

                expect(subject.forms).to be_truthy
                expect(subject.elements?( :forms )).to be_truthy
                expect(subject.elements?( :form )).to be_truthy
                expect(subject.elements?( 'forms' )).to be_truthy
                expect(subject.elements?( 'form' )).to be_truthy

                expect(subject.cookies).to be_truthy
                expect(subject.elements?( :cookies )).to be_truthy
                expect(subject.elements?( :cookie )).to be_truthy
                expect(subject.elements?( 'cookies' )).to be_truthy
                expect(subject.elements?( 'cookie' )).to be_truthy

                expect(subject.headers).to be_truthy
                expect(subject.elements?( :headers )).to be_truthy
                expect(subject.elements?( :header )).to be_truthy
                expect(subject.elements?( 'headers' )).to be_truthy
                expect(subject.elements?( 'header' )).to be_truthy

                expect(subject.link_templates).to be_any
                expect(subject.elements?( :link_templates )).to be_truthy
                expect(subject.elements?( :link_template )).to be_truthy
                expect(subject.elements?( 'link_templates' )).to be_truthy
                expect(subject.elements?( 'link_template' )).to be_truthy

                expect(subject.elements?( :header, :link, :form, :cookie, :link_template )).to be_truthy
                expect(subject.elements?( [:header, :link, :form, :cookie, :link_template] )).to be_truthy
            end
        end
        context 'if the given element is not to be audited' do
            it 'returns false' do
                expect(subject.links).to be_falsey
                expect(subject.elements?( :links )).to be_falsey
                expect(subject.elements?( :link )).to be_falsey
                expect(subject.elements?( 'links' )).to be_falsey
                expect(subject.elements?( 'link' )).to be_falsey

                expect(subject.forms).to be_falsey
                expect(subject.elements?( :forms )).to be_falsey
                expect(subject.elements?( :form )).to be_falsey
                expect(subject.elements?( 'forms' )).to be_falsey
                expect(subject.elements?( 'form' )).to be_falsey

                expect(subject.cookies).to be_falsey
                expect(subject.elements?( :cookies )).to be_falsey
                expect(subject.elements?( :cookie )).to be_falsey
                expect(subject.elements?( 'cookies' )).to be_falsey
                expect(subject.elements?( 'cookie' )).to be_falsey

                expect(subject.headers).to be_falsey
                expect(subject.elements?( :headers )).to be_falsey
                expect(subject.elements?( :header )).to be_falsey
                expect(subject.elements?( 'headers' )).to be_falsey
                expect(subject.elements?( 'header' )).to be_falsey

                expect(subject.link_templates).to be_empty
                expect(subject.elements?( :link_templates )).to be_falsey
                expect(subject.elements?( :link_template )).to be_falsey
                expect(subject.elements?( 'link_templates' )).to be_falsey
                expect(subject.elements?( 'link_template' )).to be_falsey

                expect(subject.elements?( :header, :link, :form, :cookie, :link_templates )).to be_falsey
                expect(subject.elements?( [:header, :link, :form, :cookie, :link_templates] )).to be_falsey
            end
        end

        context 'when given an invalid element type' do
            it "raises #{described_class::Error::InvalidElementType}" do
                expect do
                    subject.elements? :stuff
                end.to raise_error described_class::Error::InvalidElementType
            end
        end
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "converts 'link_templates' to strings" do
            subject.link_templates << /param\/(?<param>\w+)/
            expect(data['link_templates']).to eq(subject.link_templates.map(&:source))
        end
    end
end
