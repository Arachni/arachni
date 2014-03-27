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
