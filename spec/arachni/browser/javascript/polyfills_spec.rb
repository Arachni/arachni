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

    describe 'Function.prototype.bind' do
        it 'is implemented' do
            expect(subject.run(
                <<EOJS
this.x = 9;
var module = {
    x: 81,
    getX: function() { return this.x; }
};
return module.getX.bind( module )()
EOJS
            )).to eq 81
        end
    end

end
