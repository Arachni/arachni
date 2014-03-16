require 'spec_helper'

describe Arachni::ElementFilter do

    before( :all ) do
        @edb = Class.new
        @edb.extend Arachni::ElementFilter

        @page = Arachni::Page.new(
            :url => 'http://blah.com',
            :links => [
                Arachni::Element::Link.new(
                    url:    'http://blah.com',
                    inputs: {
                        'link_input' => 'link_value'
                    }
                )
            ],
            :forms => [
                Arachni::Element::Form.new(
                    url:    'http://blah.com',
                    inputs: {
                        'form_input' => 'form_value'
                    }
                )
            ],
            :cookies => [
                Arachni::Element::Cookie.new(
                    url:    'http://blah.com',
                    inputs: {
                        'cookie_input' => 'cookie_value'
                    }
                )
            ],
            :headers => [
                Arachni::Element::Header.new(
                    url:    'http://blah.com',
                    inputs: {
                        'header_input' => 'header_value'
                    }
                )
            ]
        )

        @edb.init_db_from_page( @page )
    end

    describe '#update_links' do
        context 'when there are new links' do
            it 'adds them to the DB and return them' do
                link = Arachni::Element::Link.new(
                    url:    'http://blah.com',
                    inputs: {
                        'new_link_input' => 'new_link_value'
                    }
                )
                @edb.update_links( [link] | @page.links ).should == 1
            end
        end

        context 'when there are no new links' do
            it 'returns empty results' do
                @edb.update_links( @page.links ).should == 0
            end
        end
    end

    describe '#update_forms' do
        context 'when there are new forms' do
            it 'adds them to the DB and return them' do
                form = Arachni::Element::Form.new(
                    url:    'http://blah.com',
                    inputs: {
                        'new_form_input' => 'new_form_value'
                    }
                )
                @edb.update_forms( [form] | @page.forms ).should == 1
            end
        end

        context 'when there are no new links' do
            it 'returns empty results' do
                @edb.update_forms( @page.forms ).should == 0
            end
        end
    end

    describe '#update_cookies' do
        context 'when there are new cookies' do
            it 'adds them to the DB, return all cookies but only return the count of the new ones' do
                cookie = Arachni::Element::Cookie.new(
                    url:    'http://blah.com',
                    inputs: { 'new_cookie_input' => 'new_cookie_value' }
                )
                cookies = [cookie] | @page.cookies
                @edb.update_cookies( cookies ).should == 1
            end
        end

        context 'when there are cookies with existing names but have different values' do
            it 'updates the values' do
                cookie = Arachni::Element::Cookie.new(
                    url:    'http://blah.com',
                    inputs: { 'cookie_input' => 'foo!' }
                )
                @edb.update_cookies( [cookie] | @page.cookies ).should == 0
            end
        end

        context 'when there are no new cookies' do
            it 'returns empty results' do
                @edb.update_cookies( @page.cookies ).should == 0
            end
        end
    end

end
