require 'spec_helper'

describe 'Arachni::Browser::Javascript::Polyfiils' do

    before( :all ) do
        @url = Arachni::Utilities.normalize_url( web_server_url_for( :browser ) )
    end

    before( :each ) do
        @browser = Arachni::Browser.new
        @browser.load @url
    end

    after( :each ) do
        @browser.shutdown
    end

    subject { @browser.javascript }

end
