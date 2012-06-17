require_relative '../../spec_helper'

describe 'Arachni::Modules::PathTraversal' do

    before( :all ) do
        @name = File.basename( __FILE__, '_spec.rb' )

        opts = Arachni::Options.instance.reset

        @url = server_url_for( @name ) + '/'
        opts.url = @url

        @f = Arachni::Framework.new
        @f.modules.load @name

        @issue_sizes = {
            unix:    10,
            windows: 10
        }
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

    after( :all ){ @f.modules.clear }

    %w(Unix Windows).each do |system|
        context system do
            before( :all ) { @f.opts.url = @url + system.downcase }

            it 'should audit links' do
                @f.opts.audit_links = true
                @f.run
                issues.size.should == 12
                issues.map { |i| i.elem }.uniq.should == [Arachni::Issue::Element::LINK]
            end

            it 'should audit forms' do
                @f.opts.audit_forms = true
                @f.run
                issues.size.should == 12
                issues.map { |i| i.elem }.uniq.should == [Arachni::Issue::Element::FORM]
            end

            it 'should audit cookies' do
                @f.opts.audit_cookies = true
                @f.run
                issues.size.should == 12
                issues.map { |i| i.elem }.uniq.should == [Arachni::Issue::Element::COOKIE]
            end

            it 'should audit headers' do
                @f.opts.audit_headers = true
                @f.http.headers['User-Agent'] = 'default'
                @f.run
                issues.size.should == 12
                issues.map { |i| i.elem }.uniq.should == [Arachni::Issue::Element::HEADER]
            end

        end
    end

end
