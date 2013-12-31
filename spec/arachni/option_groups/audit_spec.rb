require 'spec_helper'

describe Arachni::OptionGroups::Audit do
    include_examples 'option_group'
    subject { described_class.new }

    %w(with_both_http_methods exclude_binaries exclude_vectors links forms
        cookies cookies_extensively headers).each do |method|
        it { should respond_to method }
        it { should respond_to "#{method}=" }
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

            subject.links.should be_true
            subject.forms.should be_true
            subject.cookies.should be_true
            subject.headers.should be_true

            subject.skip_elements :links, :forms, :cookies, :headers

            subject.links.should be_false
            subject.forms.should be_false
            subject.cookies.should be_false
            subject.headers.should be_false
        end
    end

    describe '#elements?' do
        context 'if the given element is to be audited' do
            it 'returns true' do
                subject.elements :links, :forms, :cookies, :headers

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

                subject.elements?( :header, :link, :form, :cookie ).should be_true
                subject.elements?( [:header, :link, :form, :cookie] ).should be_true
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

                subject.elements?( :header, :link, :form, :cookie ).should be_false
                subject.elements?( [:header, :link, :form, :cookie] ).should be_false
            end
        end
    end
end
