require_relative '../../spec_helper'

describe 'Arachni::Modules::CodeInjection' do

    before( :all ) do
        #require_relative '../../../lib/arachni/ui/cli/output'

        @name = File.basename( __FILE__, '_spec.rb' )

        opts = Arachni::Options.instance.reset

        @url = server_url_for( @name ) + '/'
        opts.url = @url

        @f = Arachni::Framework.new

        @f.http.cookie_jar << Arachni::Parser::Element::Cookie.new( @url, 'logged_in' => 'true' )

        @f.opts.url = @url
        @f.opts.audit_forms = false

        @f.modules.load @name
    end

    after( :each ) do
        Arachni::Module::ElementDB.reset
        Arachni::Parser::Element::Auditable.reset
        issues.clear

        @f.http.cookie_jar.clear
        @f.http.cookie_jar << Arachni::Parser::Element::Cookie.new( @url, 'logged_in' => 'true' )
    end

    it 'should log forms that lack CSRF protection' do
        @f.opts.audit_forms = true
        @f.run
        issues.size.should == 1
        issues.first.var.should == 'insecure_important_form'
    end

    it 'should not log forms that have an anti-CSRF token in a name attribute' do
        @f.opts.url = @url + 'token_in_name'
        @f.run
        issues.size.should == 1
        issues.first.var.should == 'insecure_important_form'
    end

    it 'should not log forms that have an anti-CSRF token in their action URL' do
        @f.opts.url = @url + 'token_in_action'
        @f.run
        issues.size.should == 1
        issues.first.var.should == 'insecure_important_form'
    end

end
