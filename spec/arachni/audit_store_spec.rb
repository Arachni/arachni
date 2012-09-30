require_relative '../spec_helper'

describe Arachni::AuditStore do

    before( :all ) do
        url = 'http://test.com'

        @opts = Arachni::Options.instance
        @opts.url = url

        @issue = Arachni::Issue.new(
            url: url,
            name: 'blah',
            mod_name: 'mod',
            elem: 'link'
        )

        @plugin_results = { 'name' => { results: 'stuff' } }

        @auditstore_opts = {
            version:  '0.1',
            revision: '0.2',
            options:  @opts.to_h,
            sitemap:  [@opts.url],
            issues:   [@issue.deep_clone],
            plugins:  @plugin_results,
        }

        @auditstore = Arachni::AuditStore.new(
            @auditstore_opts.merge(
                start_datetime: Time.now.asctime,
                finish_datetime: Time.now.asctime
            ).deep_clone
        )

        @clean = Arachni::AuditStore.new( @auditstore_opts )
    end

    describe '#version' do
        it 'should return the version number' do
            @auditstore.version.should == '0.1'
        end
    end

    describe '#revision' do
        it 'should return the revision number' do
            @auditstore.revision.should == '0.2'
        end
    end

    describe '#options' do
        it 'should return the options as a hash' do
            h = Arachni::Options.instance.to_h
            h['url'] = h['url'].to_s
            ah = @auditstore.options
            ah['cookies'] = nil
            h['cookies'] = nil
            ah.should == h
        end
    end

    describe '#sitemap' do
        it 'should return the sitemap' do
            @auditstore.sitemap.should == [@opts.url.to_s]
        end
    end

    describe '#issues' do
        it 'should return the issues' do
            @auditstore.issues.should == [@issue]
        end
    end

    describe '#plugins' do
        it 'should return the plugin results' do
            @auditstore.plugins.should == @plugin_results
        end
    end

    describe '#start_datetime' do
        it 'should return the start datetime of the scan' do
            Time.parse( @auditstore.start_datetime ).is_a?( Time ).should be_true
        end
        context 'when no start datetime info has been provided' do
            it 'should revert to Time.now' do
                Time.parse( @clean.start_datetime ).is_a?( Time ).should be_true
            end
        end
    end

    describe '#finish_datetime' do
        it 'should return the start finish of the scan' do
            Time.parse( @auditstore.finish_datetime ).is_a?( Time ).should be_true
        end
        context 'when no start datetime info has been provided' do
            it 'should revert to Time.now' do
                Time.parse( @clean.finish_datetime ).is_a?( Time ).should be_true
            end
        end
    end

    describe '#delta_time' do
        it 'should return the time difference between start and finish time' do
            Time.parse( @auditstore.delta_time ).is_a?( Time ).should be_true
        end
    end

    it 'should organize identical issues into variations' do
        url = 'http://test.com'
        i = Arachni::Issue.new(
            url: url,
            name: 'blah',
            mod_name: 'mod',
            elem: 'link',
            var: 'varname'
        )
        issues = [
            i.deep_clone, i.deep_clone,
            Arachni::Issue.new(
                url: url,
                name: 'blah',
                mod_name: 'mod',
                elem: 'link',
                var: 'varname2'
            )
        ]
        organized = Arachni::AuditStore.new( @auditstore_opts.merge( issues: issues.deep_clone ) ).issues
        organized.first.variations.size.should == 2

        identical = %w(name url mod_name elem var)
        organized.first.variations.each do |v|
            identical.each { |attr| v.send( attr ).should == i.send( attr ) }
        end

        organized.last.variations.size.should == 1
        organized.last.variations.each do |v|
            identical.each { |attr| v.send( attr ).should == issues.last.send( attr ) }
        end
    end

    it 'should sort the issues based on severity' do
        url = 'http://test.com'
        opts = {
            url: url,
            mod_name: 'mod',
            elem: 'link',
        }
        high = Arachni::Issue.new( opts.merge(
            severity: ::Arachni::Issue::Severity::HIGH,
            name: 'blah1'
        ))
        medium = Arachni::Issue.new( opts.merge(
            severity: ::Arachni::Issue::Severity::MEDIUM,
            name: 'blah2'
        ))
        low = Arachni::Issue.new( opts.merge(
            severity: ::Arachni::Issue::Severity::LOW,
            name: 'blah3'
        ))
        info = Arachni::Issue.new( opts.merge(
            severity: ::Arachni::Issue::Severity::INFORMATIONAL,
            name: 'blah4'
        ))

        issues = [low, medium, info, high]
        sorted = Arachni::AuditStore.new( @auditstore_opts.merge( issues: issues ) ).issues
        sorted.map { |i| i.severity }.should == [high.severity, medium.severity, low.severity, info.severity]
    end

    describe '#save' do
        it 'should serialize and save the object to a file' do
            filename = 'auditstore'
            auditstore = ::Arachni::AuditStore.new( @auditstore_opts )
            auditstore.save( filename )

            loaded = ::Arachni::AuditStore.load( filename )
            File.delete( filename )

            auditstore.instance_variables.each do |v|
                if v.to_s != '@issues'
                    loaded.instance_variable_get( v ).should == auditstore.instance_variable_get( v )
                else
                    loaded.issues.size.should == auditstore.issues.size
                end
            end
        end
    end

    describe '#to_hash' do
        it 'should return the object as a hash' do
            h = @auditstore.to_hash
            h.is_a?( Hash ).should be_true

            h.each do |k, v|
                if k.to_s != 'issues'
                    @auditstore.instance_variable_get( "@#{k}".to_sym ).should == v
                else
                    @auditstore.issues.size.should == v.size
                end
            end
        end
        it 'should be aliased to #to_h' do
            @auditstore.to_hash.should == @auditstore.to_h
        end
    end

    describe '#==' do
        context 'when the auditstores are equal' do
            it 'should return true' do
                a = @auditstore.deep_clone
                a.should == @auditstore
            end
        end
        context 'when the auditstores are not equal' do
            it 'should return false' do
                a = @auditstore.deep_clone
                a.options['url'] = ''
                a.should_not == @auditstore
            end
        end
    end

end
