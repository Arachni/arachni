require 'spec_helper'

describe Arachni::AuditStore do

    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.url = 'http://test.com'
    end

    after :each do
        File.delete( @report_file ) rescue nil
    end

    let( :audit_store_data ) { Factory[:audit_store_data] }
    let( :audit_store ) { Factory[:audit_store] }
    let( :audit_store_empty ) { Factory[:audit_store_empty] }
    let( :passive_issue ) { Factory[:passive_issue] }
    let( :active_issue ) { Factory[:active_issue] }

    it "supports #{Arachni::Serializer}" do
        audit_store.should == Arachni::Serializer.deep_clone( audit_store )
    end

    describe '#version' do
        it 'returns the version number' do
            audit_store.version.should == Arachni::VERSION
        end
    end

    describe '#options' do
        it 'returns Arachni::Options as a hash' do
           audit_store.options.should == Arachni::Options.to_h
        end

        it 'defaults to Arachni::Options.to_h' do
            described_class.new.options.should == Arachni::Options.to_h
        end
    end

    describe '#sitemap' do
        it 'returns the sitemap' do
            audit_store.sitemap.should == {@opts.url.to_s => 200}
        end
    end

    describe '#issues' do
        it 'returns the issues' do
            issues = [Factory[:issue]]
            described_class.new( issues: issues ).issues.should == issues
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

    describe '#plugins' do
        it 'returns the plugin results' do
            audit_store.plugins.should == Factory[:audit_store_data][:plugins]
        end
    end

    describe '#start_datetime' do
        it 'returns a Time object' do
            audit_store.start_datetime.should be_kind_of Time
        end
        context 'when no start datetime info has been provided' do
            it 'falls-back to Time.now' do
                audit_store_empty.start_datetime.should be_kind_of Time
            end
        end
    end

    describe '#finish_datetime' do
        it 'returns a Time object' do
            audit_store.finish_datetime.should be_kind_of Time
        end
        it 'returns the start finish of the scan' do
            audit_store.finish_datetime.to_s.should ==
                Factory[:audit_store_data][:finish_datetime].to_s
        end
        context 'when no start datetime info has been provided' do
            it 'falls-back to Time.now' do
                audit_store_empty.finish_datetime.should be_kind_of Time
            end
        end
    end

    describe '#delta_time' do
        it 'returns the time difference between start and finish time' do
            audit_store.delta_time.should == '02:46:40'
        end
        context 'when no #finish_datetime has been provided' do
            it 'uses Time.now for the calculation' do
                audit_store_empty.start_datetime = Time.now - 2000
                audit_store_empty.delta_time.to_s.should == '00:33:19'
            end
        end
    end

    describe '#save' do
        it 'dumps the object to a file' do
            @report_file = audit_store.save

            described_class.load( @report_file ).should == audit_store
        end

        context 'when given a location' do
            context 'which is a filepath' do
                it 'saves the object to that file' do
                    @report_file = 'auditstore'
                    audit_store.save( @report_file )

                    described_class.load( @report_file ).should == audit_store
                end
            end

            context 'which is a directory' do
                it 'saves the object under that directory' do
                    directory = '/tmp/'
                    @report_file = audit_store.save( directory )

                    described_class.load( @report_file ).should == audit_store
                end
            end
        end
    end

    describe '#to_h' do
        it 'returns the object as a hash' do
            audit_store.to_h.should == {
                version:         audit_store.version,
                options:         audit_store.options,
                sitemap:         audit_store.sitemap,
                start_datetime:  audit_store.start_datetime.to_s,
                finish_datetime: audit_store.finish_datetime.to_s,
                delta_time:      audit_store.delta_time,
                issues:          audit_store.issues.map(&:to_h),
                plugins:         {
                    plugin_name: {
                        results: 'stuff',
                        options: [
                            {
                                name:        :some_name,
                                required:    false,
                                value:       nil,
                                description: 'Some description.',
                                default:     'default_value',
                                choices:      %w(available values go here),
                                type:        :multiple_choice,
                                class:       'Arachni::Component::Options::MultipleChoice'
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
