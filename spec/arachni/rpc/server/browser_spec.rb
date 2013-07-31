require 'spec_helper'

describe 'Arachni::RPC::Server::Browser' do
    before( :all ) do
        @url = Arachni::Utilities.normalize_url( web_server_url_for( :browser ) )

        @browser = Arachni::RPC::Server::Browser.spawn
    end

    after( :all ){ @browser.close }

    def pages_should_have_form_with_input( pages, input_name )
        pages.find do |page|
            page.forms.find { |form| form.inputs.include? input_name }
        end.should be_true
    end

    describe 'analyze' do
        it 'triggers all events on all elements and follows all javascript links' do
            pages = @browser.analyze( @url + '/explore' )

            pages_should_have_form_with_input pages, 'by-ajax'
            pages_should_have_form_with_input pages, 'ajax-token'
            pages_should_have_form_with_input pages, 'href-post-name'
        end
    end
end
