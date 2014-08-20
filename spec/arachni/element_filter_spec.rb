require 'spec_helper'

describe Arachni::ElementFilter do
    before( :each ) { described_class.reset }

    subject { described_class }
    let(:page) { Factory[:page] }
    let(:link) do
        Arachni::Element::Link.new(
            url:    'http://blah.com',
            inputs: {
                'new_link_input' => 'new_link_value'
            }
        )
    end
    let(:form) do
        Arachni::Element::Form.new(
            url:    'http://blah.com',
            inputs: {
                'new_form_input' => 'new_form_value'
            }
        )
    end
    let(:cookie) do
        Arachni::Element::Cookie.new(
            url:    'http://blah.com',
            inputs: { 'new_cookie_input' => 'new_cookie_value' }
        )
    end

    describe '#forms' do
        it "keeps track of forms by #{Arachni::Element::Form}#id" do
            subject.forms.should be_empty
            subject.update_forms form
            subject.forms.should be_any
            subject.forms.should include form.id
        end

        it "returns a #{Arachni::Support::LookUp::HashSet}" do
            subject.forms.should be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#links' do
        it "keeps track of links by #{Arachni::Element::Link}#id" do
            subject.links.should be_empty
            subject.update_links link
            subject.links.should be_any
            subject.links.should include link.id
        end

        it "returns a #{Arachni::Support::LookUp::HashSet}" do
            subject.links.should be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#cookies' do
        it "keeps track of cookies by #{Arachni::Element::Link}#id" do
            subject.cookies.should be_empty
            subject.update_cookies cookie
            subject.cookies.should be_any
            subject.cookies.should include cookie.id
        end

        it "returns a #{Arachni::Support::LookUp::HashSet}" do
            subject.cookies.should be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#include?' do
        context 'when the given element is included' do
            it 'returns true' do
                subject.update_links link
                subject.update_forms form
                subject.update_cookies cookie

                subject.should include link
                subject.should include form
                subject.should include cookie
            end
        end

        context 'when the given element is not included' do
            it 'returns false' do
                subject.should_not include link
            end
        end
    end

    describe '#forms_include?' do
        context 'when #forms includes the given form' do
            it 'returns true' do
                subject.forms.should be_empty
                subject.update_forms form
                subject.forms.should be_any
                subject.forms_include?( form ).should be_true
            end
        end

        context 'when #forms does not include the given form' do
            it 'returns false' do
                subject.forms_include?( form ).should be_false
            end
        end
    end

    describe '#links_include?' do
        context 'when #links includes the given form' do
            it 'returns true' do
                subject.links.should be_empty
                subject.update_links link
                subject.links.should be_any
                subject.links_include?( link ).should be_true
            end
        end

        context 'when #links does not include the given form' do
            it 'returns false' do
                subject.links_include?( link ).should be_false
            end
        end
    end

    describe '#cookies_include?' do
        context 'when #cookies includes the given form' do
            it 'returns true' do
                subject.cookies.should be_empty
                subject.update_cookies cookie
                subject.cookies.should be_any
                subject.cookies_include?( cookie ).should be_true
            end
        end

        context 'when #cookies does not include the given form' do
            it 'returns false' do
                subject.cookies_include?( cookie ).should be_false
            end
        end
    end

    describe '#update_from_page' do
        context 'when there are new elements' do
            it 'adds them to the list' do
                subject.update_from_page( page )

                (page.links | page.forms | page.cookies).each do |element|
                    subject.should include element
                end
            end

            it 'returns the amount of new ones' do
                subject.update_links( page.links )
                subject.update_from_page( page ).should == (page.forms | page.cookies).size
            end
        end

        context 'when there are no new elements' do
            it 'returns 0' do
                subject.update_from_page( page )
                subject.update_from_page( page ).should == 0
            end
        end
    end

    describe '#update_from_page_cache' do
        context 'when there are new elements in the Page#cache' do
            it 'adds them to the list' do
                page.cache.should_not include :links
                page.links
                page.cache[:links].should == page.links

                subject.update_from_page_cache( page )

                page.links.each do |element|
                    subject.should include element
                end

                (page.forms | page.cookies).each do |element|
                    subject.should_not include element
                end
            end

            it 'returns the amount of new ones' do
                page.links
                subject.update_from_page_cache( page ).should == page.links.size
            end
        end

        context 'when there are no new elements in the Page#cache' do
            it 'returns 0' do
                page.elements.should be_any
                subject.update_from_page_cache( page ).should ==
                    (page.links | page.forms | page.cookies).size
                subject.update_from_page_cache( page ).should == 0
            end
        end
    end

    describe '#update_links' do
        context 'when there are new links' do
            it 'adds them to the list' do
                subject.update_links( link )
                subject.links_include?( link ).should be_true
            end

            it 'returns the amount of new ones' do
                subject.update_links( page.links )
                subject.update_links( [link] | page.links ).should == 1
            end
        end

        context 'when there are no new links' do
            it 'returns 0' do
                subject.update_links( page.links )
                subject.update_links( page.links ).should == 0
            end
        end
    end
    
    describe '#update_forms' do
        context 'when there are new links' do
            it 'adds them to the list' do
                subject.update_forms( form )
                subject.forms_include?( form ).should be_true
            end

            it 'returns the amount of new ones' do
                subject.update_forms( page.forms )
                subject.update_forms( [form] | page.forms ).should == 1
            end
        end
    
        context 'when there are no new links' do
            it 'returns 0' do
                subject.update_forms( page.forms )
                subject.update_forms( page.forms ).should == 0
            end
        end
    end
    
    describe '#update_cookies' do
        context 'when there are new links' do
            it 'adds them to the list' do
                subject.update_cookies( cookie )
                subject.cookies_include?( cookie ).should be_true
            end

            it 'returns the amount of new ones' do
                subject.update_cookies( page.cookies )
                subject.update_cookies( [cookie] | page.cookies ).should == 1
            end
        end
    
        context 'when there are no new cookies' do
            it 'returns 0' do
                subject.update_cookies( page.cookies )
                subject.update_cookies( page.cookies ).should == 0
            end
        end
    end

end
