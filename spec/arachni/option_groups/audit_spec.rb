require 'spec_helper'

describe Arachni::OptionGroups::Audit do
    include_examples 'option_group'
    subject { described_class.new }

    %w(with_both_http_methods exclude_binaries exclude_vectors links forms
        cookies cookies_extensively headers link_templates).each do |method|
        it { should respond_to method }
        it { should respond_to "#{method}=" }
    end

    describe '#link_templates=' do
        it 'converts its param to an Array of Regexp' do
            templates = %w(/param\/(?<param>\w+)/ /param2\/(?<param2>\w+)/)

            subject.link_templates = templates.first
            subject.link_templates.should == [Regexp.new( templates.first )]

            subject.link_templates = templates
            subject.link_templates.should == templates.map { |p| Regexp.new( p ) }
        end

        context 'when given nil' do
            it 'empties the templates' do
                subject.link_templates = /param\/(?<param>\w+)/
                subject.link_templates.should be_any
                subject.link_templates = nil
                subject.link_templates.should be_empty
            end
        end

        context 'when given false' do
            it 'empties the templates' do
                subject.link_templates = /param\/(?<param>\w+)/
                subject.link_templates.should be_any
                subject.link_templates = false
                subject.link_templates.should be_empty
            end
        end

        context 'when given an invalid template' do
            it "raises #{described_class::Error::InvalidLinkTemplate}" do
                expect { subject.link_templates = /(.*)/ }.to raise_error
                described_class::Error::InvalidLinkTemplate
            end
        end
    end

    describe '#link_templates?' do
        context 'when templates are available' do
            it 'returns true' do
                subject.link_templates << /param\/(?<param>\w+)/
                subject.link_templates?.should == true
            end
        end

        context 'when templates not available' do
            it 'returns false' do
                subject.link_templates?.should == false
            end
        end
    end

    [:links, :forms, :cookies, :headers, :cookies_extensively,
     :with_both_http_methods, :exclude_binaries, :link_doms, :form_doms,
     :cookie_doms].each do |attribute|
        describe "#{attribute}?" do
            context "when ##{attribute} is" do
                context true do
                    it 'returns true' do
                        subject.send "#{attribute}=", true
                        subject.send("#{attribute}?").should == true
                    end
                end

                context false do
                    it 'returns false' do
                        subject.send "#{attribute}=", false
                        subject.send("#{attribute}?").should == false
                    end
                end

                context 'nil' do
                    it 'returns false' do
                        subject.send "#{attribute}=", false
                        subject.send("#{attribute}?").should == false
                    end
                end
            end
        end
    end

    describe '#exclude_vectors=' do
        it 'converts the argument to a flat array of strings' do
            subject.exclude_vectors = [ [:test], 'string' ]
            subject.exclude_vectors.should == %w(test string)
        end
    end

    describe '#elements' do
        it 'enables auditing of the given element types' do
            subject.links.should be_false
            subject.forms.should be_false
            subject.cookies.should be_false
            subject.headers.should be_false

            subject.elements :links, :forms, :cookies, :headers

            subject.links.should be_true
            subject.forms.should be_true
            subject.cookies.should be_true
            subject.headers.should be_true
        end
    end

    describe '#elements=' do
        it 'enables auditing of the given element types' do
            subject.links.should be_false
            subject.forms.should be_false
            subject.cookies.should be_false
            subject.headers.should be_false

            subject.elements = :links, :forms, :cookies, :headers

            subject.links.should be_true
            subject.forms.should be_true
            subject.cookies.should be_true
            subject.headers.should be_true
        end
    end

    describe '#skip_elements' do
        it 'enables auditing of the given element types' do
            subject.elements :links, :forms, :cookies, :headers
            subject.link_templates = /param\/(?<param>\w+)/

            subject.links?.should be_true
            subject.forms?.should be_true
            subject.cookies?.should be_true
            subject.headers?.should be_true
            subject.link_templates?.should be_true

            subject.skip_elements :links, :forms, :cookies, :headers, :link_templates

            subject.links?.should be_false
            subject.forms?.should be_false
            subject.cookies?.should be_false
            subject.headers?.should be_false
            subject.link_templates?.should be_false
        end
    end

    describe '#elements?' do
        context 'if the given element is to be audited' do
            it 'returns true' do
                subject.elements :links, :forms, :cookies, :headers
                subject.link_templates << /param\/(?<param>\w+)/

                subject.links.should be_true
                subject.elements?( :links ).should be_true
                subject.elements?( :link ).should be_true
                subject.elements?( 'links' ).should be_true
                subject.elements?( 'link' ).should be_true

                subject.forms.should be_true
                subject.elements?( :forms ).should be_true
                subject.elements?( :form ).should be_true
                subject.elements?( 'forms' ).should be_true
                subject.elements?( 'form' ).should be_true

                subject.cookies.should be_true
                subject.elements?( :cookies ).should be_true
                subject.elements?( :cookie ).should be_true
                subject.elements?( 'cookies' ).should be_true
                subject.elements?( 'cookie' ).should be_true

                subject.headers.should be_true
                subject.elements?( :headers ).should be_true
                subject.elements?( :header ).should be_true
                subject.elements?( 'headers' ).should be_true
                subject.elements?( 'header' ).should be_true

                subject.link_templates.should be_any
                subject.elements?( :link_templates ).should be_true
                subject.elements?( :link_template ).should be_true
                subject.elements?( 'link_templates' ).should be_true
                subject.elements?( 'link_template' ).should be_true

                subject.elements?( :header, :link, :form, :cookie, :link_template ).should be_true
                subject.elements?( [:header, :link, :form, :cookie, :link_template] ).should be_true
            end
        end
        context 'if the given element is not to be audited' do
            it 'returns false' do
                subject.links.should be_false
                subject.elements?( :links ).should be_false
                subject.elements?( :link ).should be_false
                subject.elements?( 'links' ).should be_false
                subject.elements?( 'link' ).should be_false

                subject.forms.should be_false
                subject.elements?( :forms ).should be_false
                subject.elements?( :form ).should be_false
                subject.elements?( 'forms' ).should be_false
                subject.elements?( 'form' ).should be_false

                subject.cookies.should be_false
                subject.elements?( :cookies ).should be_false
                subject.elements?( :cookie ).should be_false
                subject.elements?( 'cookies' ).should be_false
                subject.elements?( 'cookie' ).should be_false

                subject.headers.should be_false
                subject.elements?( :headers ).should be_false
                subject.elements?( :header ).should be_false
                subject.elements?( 'headers' ).should be_false
                subject.elements?( 'header' ).should be_false

                subject.link_templates.should be_empty
                subject.elements?( :link_templates ).should be_false
                subject.elements?( :link_template ).should be_false
                subject.elements?( 'link_templates' ).should be_false
                subject.elements?( 'link_template' ).should be_false

                subject.elements?( :header, :link, :form, :cookie, :link_templates ).should be_false
                subject.elements?( [:header, :link, :form, :cookie, :link_templates] ).should be_false
            end
        end
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "converts 'link_templates' to strings" do
            subject.link_templates << /param\/(?<param>\w+)/
            data['link_templates'].should == subject.link_templates.map(&:to_s)
        end
    end
end
