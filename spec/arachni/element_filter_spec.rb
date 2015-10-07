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
            expect(subject.forms).to be_empty
            subject.update_forms form
            expect(subject.forms).to be_any
            expect(subject.forms).to include form.id
        end

        it "returns a #{Arachni::Support::LookUp::HashSet}" do
            expect(subject.forms).to be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#links' do
        it "keeps track of links by #{Arachni::Element::Link}#id" do
            expect(subject.links).to be_empty
            subject.update_links link
            expect(subject.links).to be_any
            expect(subject.links).to include link.id
        end

        it "returns a #{Arachni::Support::LookUp::HashSet}" do
            expect(subject.links).to be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#cookies' do
        it "keeps track of cookies by #{Arachni::Element::Link}#id" do
            expect(subject.cookies).to be_empty
            subject.update_cookies cookie
            expect(subject.cookies).to be_any
            expect(subject.cookies).to include cookie.id
        end

        it "returns a #{Arachni::Support::LookUp::HashSet}" do
            expect(subject.cookies).to be_kind_of Arachni::Support::LookUp::HashSet
        end
    end

    describe '#include?' do
        context 'when the given element is included' do
            it 'returns true' do
                subject.update_links link
                subject.update_forms form
                subject.update_cookies cookie

                expect(subject).to include link
                expect(subject).to include form
                expect(subject).to include cookie
            end
        end

        context 'when the given element is not included' do
            it 'returns false' do
                expect(subject).not_to include link
            end
        end
    end

    describe '#forms_include?' do
        context 'when #forms includes the given form' do
            it 'returns true' do
                expect(subject.forms).to be_empty
                subject.update_forms form
                expect(subject.forms).to be_any
                expect(subject.forms_include?( form )).to be_truthy
            end
        end

        context 'when #forms does not include the given form' do
            it 'returns false' do
                expect(subject.forms_include?( form )).to be_falsey
            end
        end
    end

    describe '#links_include?' do
        context 'when #links includes the given form' do
            it 'returns true' do
                expect(subject.links).to be_empty
                subject.update_links link
                expect(subject.links).to be_any
                expect(subject.links_include?( link )).to be_truthy
            end
        end

        context 'when #links does not include the given form' do
            it 'returns false' do
                expect(subject.links_include?( link )).to be_falsey
            end
        end
    end

    describe '#cookies_include?' do
        context 'when #cookies includes the given form' do
            it 'returns true' do
                expect(subject.cookies).to be_empty
                subject.update_cookies cookie
                expect(subject.cookies).to be_any
                expect(subject.cookies_include?( cookie )).to be_truthy
            end
        end

        context 'when #cookies does not include the given form' do
            it 'returns false' do
                expect(subject.cookies_include?( cookie )).to be_falsey
            end
        end
    end

    describe '#update_from_page' do
        context 'when there are new elements' do
            it 'adds them to the list' do
                subject.update_from_page( page )

                (page.links | page.forms | page.cookies).each do |element|
                    expect(subject).to include element
                end
            end

            it 'returns the amount of new ones' do
                subject.update_links( page.links )
                expect(subject.update_from_page( page )).to eq((page.forms | page.cookies).size)
            end
        end

        context 'when there are no new elements' do
            it 'returns 0' do
                subject.update_from_page( page )
                expect(subject.update_from_page( page )).to eq(0)
            end
        end
    end

    describe '#update_from_page_cache' do
        context 'when there are new elements in the Page#cache' do
            it 'adds them to the list' do
                expect(page.cache).not_to include :links
                page.links
                expect(page.cache[:links]).to eq(page.links)

                subject.update_from_page_cache( page )

                page.links.each do |element|
                    expect(subject).to include element
                end

                (page.forms | page.cookies).each do |element|
                    expect(subject).not_to include element
                end
            end

            it 'returns the amount of new ones' do
                page.links
                expect(subject.update_from_page_cache( page )).to eq(page.links.size)
            end
        end

        context 'when there are no new elements in the Page#cache' do
            it 'returns 0' do
                expect(page.elements).to be_any
                expect(subject.update_from_page_cache( page )).to eq(
                    (page.links | page.forms | page.cookies).size
                )
                expect(subject.update_from_page_cache( page )).to eq(0)
            end
        end
    end

    describe '#update_links' do
        context 'when there are new links' do
            it 'adds them to the list' do
                subject.update_links( link )
                expect(subject.links_include?( link )).to be_truthy
            end

            it 'returns the amount of new ones' do
                subject.update_links( page.links )
                expect(subject.update_links( [link] | page.links )).to eq(1)
            end
        end

        context 'when there are no new links' do
            it 'returns 0' do
                subject.update_links( page.links )
                expect(subject.update_links( page.links )).to eq(0)
            end
        end
    end
    
    describe '#update_forms' do
        context 'when there are new links' do
            it 'adds them to the list' do
                subject.update_forms( form )
                expect(subject.forms_include?( form )).to be_truthy
            end

            it 'returns the amount of new ones' do
                subject.update_forms( page.forms )
                expect(subject.update_forms( [form] | page.forms )).to eq(1)
            end
        end
    
        context 'when there are no new links' do
            it 'returns 0' do
                subject.update_forms( page.forms )
                expect(subject.update_forms( page.forms )).to eq(0)
            end
        end
    end
    
    describe '#update_cookies' do
        context 'when there are new links' do
            it 'adds them to the list' do
                subject.update_cookies( cookie )
                expect(subject.cookies_include?( cookie )).to be_truthy
            end

            it 'returns the amount of new ones' do
                subject.update_cookies( page.cookies )
                expect(subject.update_cookies( [cookie] | page.cookies )).to eq(1)
            end
        end
    
        context 'when there are no new cookies' do
            it 'returns 0' do
                subject.update_cookies( page.cookies )
                expect(subject.update_cookies( page.cookies )).to eq(0)
            end
        end
    end

end
