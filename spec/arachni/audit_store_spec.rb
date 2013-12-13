require 'spec_helper'

describe Arachni::AuditStore do

    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.url = 'http://test.com'
    end

    let( :audit_store_data ) { Factory[:audit_store_data] }
    let( :audit_store ) { Factory[:audit_store] }
    let( :audit_store_empty ) { Factory[:audit_store_empty] }
    let( :passive_issue ) { Factory[:passive_issue] }
    let( :active_issue ) { Factory[:active_issue] }

    it 'organizes identical passive issues into variations' do
        i = passive_issue
        i.remarks.clear

        i3 = i.deep_clone
        i3.add_remark :dd3, 'ddddd3'

        i.add_remark :dd, 'ddddd'

        i2 = i.deep_clone
        i2.add_remark :dd2, 'ddddd2'

        issues = [
            i.deep_clone, i2, i3,
            active_issue
        ]

        opts = audit_store_data.merge( issues: issues.deep_clone )
        organized = Arachni::AuditStore.new( opts ).issues.reverse
        organized.first.variations.size.should == 3

        organized.first.remarks.should be_nil

        organized.first.variations.first.remarks.should == { dd: ['ddddd'] }
        organized.first.variations[1].remarks.should ==
            { dd: ['ddddd'], dd2: ['ddddd2'] }
        organized.first.variations[2].remarks.should == { dd3: ['ddddd3'] }

        # This will be the active one.
        organized.last.variations.size.should == 1
    end

    it 'sorts the issues based on severity' do
        high = passive_issue.deep_clone.tap do |i|
            i.severity = ::Arachni::Issue::Severity::HIGH
            i.name     = '1'
        end

        medium = passive_issue.deep_clone.tap do |i|
            i.severity = ::Arachni::Issue::Severity::MEDIUM
            i.name     = '2'
        end

        low = passive_issue.deep_clone.tap do |i|
            i.severity = ::Arachni::Issue::Severity::LOW
            i.name     = '3'
        end

        info = passive_issue.deep_clone.tap do |i|
            i.severity = ::Arachni::Issue::Severity::INFORMATIONAL
            i.name     = '4'
        end

        issues = [low, medium, info, high]
        sorted = Arachni::AuditStore.new( audit_store_data.merge( issues: issues ) ).issues
        sorted.map { |i| i.severity }.should ==
            [high.severity, medium.severity, low.severity, info.severity]
    end

    describe '#version' do
        it 'returns the version number' do
            audit_store.version.should == Arachni::VERSION
        end
    end

    describe '#options' do
        it 'returns the options as a hash' do
            h = Arachni::Options.instance.to_h
            h['url'] = h['url'].to_s

            ah = audit_store.options
            ah['cookies'] = nil
            h['cookies'] = nil
            ah.should == h
        end

        it 'defaults to Arachni::Options.to_h' do
            described_class.new.options.should == Arachni::Options.to_h
        end
    end

    describe '#sitemap' do
        it 'returns the sitemap' do
            audit_store.sitemap.should == [@opts.url.to_s]
        end
    end

    describe '#issues' do
        it 'returns the issues' do
            issues = [Factory[:issue]]
            described_class.new( issues: issues ).issues.should == issues
        end
    end

    describe '#plugins' do
        it 'returns the plugin results' do
            audit_store.plugins.should == Factory[:audit_store_data][:plugins]
        end
    end

    describe '#start_datetime' do
        it 'returns the start datetime of the scan' do
            Time.parse( audit_store.start_datetime ).is_a?( Time ).should be_true
        end
        context 'when no start datetime info has been provided' do
            it 'falls-back to Time.now' do
                Time.parse( audit_store_empty.start_datetime ).is_a?( Time ).should be_true
            end
        end
    end

    describe '#finish_datetime' do
        it 'returns the start finish of the scan' do
            Time.parse( audit_store.finish_datetime ).is_a?( Time ).should be_true
        end
        context 'when no start datetime info has been provided' do
            it 'falls-back to Time.now' do
                Time.parse( audit_store_empty.finish_datetime ).is_a?( Time ).should be_true
            end
        end
    end

    describe '#delta_time' do
        it 'returns the time difference between start and finish time' do
            Time.parse( audit_store.delta_time ).is_a?( Time ).should be_true
        end
    end

    describe '#issue_by_digest' do
        it 'returns an issue based on its digest' do
            audit_store.issues.should be_any

            audit_store.issues.each do |issue|
                audit_store.issue_by_digest( issue.digest ).should == issue
            end
        end
    end

    describe '#save' do
        it 'serializes and save the object to a file' do
            filename = 'auditstore'
            audit_store.save( filename )

            Arachni::AuditStore.load( filename ).should == audit_store
            File.delete( filename )
        end
    end

    describe '#to_h' do
        it 'returns the object as a hash' do
            audit_store.to_h.should == {
                version:         audit_store.version,
                options:         audit_store.options,
                sitemap:         audit_store.sitemap,
                start_datetime:  audit_store.start_datetime,
                finish_datetime: audit_store.finish_datetime,
                delta_time:      audit_store.delta_time,
                issues:          audit_store.issues.map(&:to_h),
                plugins:         {
                    'plugin_name' => {
                        results: 'stuff',
                        options: [
                            {
                                'name'     => 'some_name',
                                'required' => false,
                                'desc'     => 'Some description.',
                                'default'  => 'default_value',
                                'enums'    => %w(available values go here),
                                'type'     => 'enum'
                            }
                        ]
                    }
                }
            }
        end
    end

    describe '#to_hash' do
        it 'alias of #to_h' do
            audit_store.to_h.should == audit_store.to_hash
        end
    end

    describe '#==' do
        context 'when the auditstores are equal' do
            it 'returns true' do
                audit_store.deep_clone.should == audit_store
            end
        end
        context 'when the auditstores are not equal' do
            it 'returns false' do
                a = audit_store.deep_clone
                a.options['url'] = ''
                a.should_not == audit_store
            end
        end
    end

end
