require_relative '../../spec_helper'

describe 'Arachni::Modules::CodeInjection' do

    before( :all ) do
        @name = File.basename( __FILE__, '_spec.rb' )

        opts = Arachni::Options.instance.reset

        @url = server_url_for( @name ) + '/'
        opts.url = @url

        @f = Arachni::Framework.new
        @f.modules.load @name
    end

    after( :each ) do
        Arachni::Module::ElementDB.reset
        Arachni::Parser::Element::Auditable.reset
        Arachni::Module::Manager.results.clear

        @f.http.cookie_jar.clear

        @f.opts.audit_links = false
        @f.opts.audit_forms = false
        @f.opts.audit_cookies = false
        @f.opts.audit_headers = false
    end

    it 'should audit links' do
        issues.should be_empty
        @f.opts.audit_links = true
        @f.run
        issues.size.should == @f.modules[@name].error_strings.size
        issues.map { |i| i.elem }.uniq.should == [Arachni::Issue::Element::LINK]
    end

    it 'should audit forms' do
        issues.should be_empty
        @f.opts.audit_forms = true
        @f.run
        issues.size.should == @f.modules[@name].error_strings.size
        issues.map { |i| i.elem }.uniq.should == [Arachni::Issue::Element::FORM]
    end

    it 'should audit cookies' do
        issues.should be_empty
        @f.opts.audit_cookies= true
        @f.run
        issues.size.should == @f.modules[@name].error_strings.size
        issues.map { |i| i.elem }.uniq.should == [Arachni::Issue::Element::COOKIE]
    end

    it 'should audit headers' do
        issues.should be_empty
        @f.opts.audit_headers = true
        @f.run
        issues.size.should == @f.modules[@name].error_strings.size
        issues.map { |i| i.elem }.uniq.should == [Arachni::Issue::Element::HEADER]
    end

end
