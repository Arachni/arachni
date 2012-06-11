require_relative '../../spec_helper'

describe 'Arachni::Modules::CodeInjectionTiming' do

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

        @f.modules.clear
        @f.modules.load @name
    end

    after( :all ){ @f.modules.clear }

    %w(Java ASP Python PHP Perl Ruby).each do |lang|
        context lang do
            before( :all ) { @f.opts.url = @url + lang.downcase }

            it 'should audit links' do
                @f.opts.audit_links = true
                @f.run
                issues.size.should == 3
                issues.map { |i| i.elem }.uniq.should == [Arachni::Issue::Element::LINK]
            end

            it 'should audit forms' do
                @f.opts.audit_forms = true
                @f.run
                issues.size.should == 3
                issues.map { |i| i.elem }.uniq.should == [Arachni::Issue::Element::FORM]
            end

            it 'should audit cookies' do
                @f.opts.audit_cookies = true
                @f.run
                issues.size.should == 3
                issues.map { |i| i.elem }.uniq.should == [Arachni::Issue::Element::COOKIE]
            end

            it 'should audit headers' do
                @f.opts.audit_headers = true
                @f.http.headers['User-Agent'] = 'default'
                @f.run
                issues.size.should == 2
                issues.map { |i| i.elem }.uniq.should == [Arachni::Issue::Element::HEADER]
            end

        end
    end

end
