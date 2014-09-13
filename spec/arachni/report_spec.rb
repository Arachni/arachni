require 'spec_helper'

describe Arachni::Report do

    before( :all ) do
        @opts = Arachni::Options.instance
        @opts.url = 'http://test.com'
    end

    after :each do
        File.delete( @report_file ) rescue nil
    end

    let( :report_data ) { Factory[:report_data] }
    let( :report ) { Factory[:report] }
    let( :report_empty ) { Factory[:report_empty] }
    let( :passive_issue ) { Factory[:passive_issue] }
    let( :active_issue ) { Factory[:active_issue] }

    it "supports #{Arachni::RPC::Serializer}" do
        report.options.delete :input

        cloned = Arachni::RPC::Serializer.deep_clone( report )
        cloned.options.delete :input

        report.should == cloned
    end

    describe '#to_rpc_data' do
        let(:subject) { report }
        let(:data) { subject.to_rpc_data }

        %w(sitemap version).each do |attribute|
            it "includes '#{attribute}'" do
                data[attribute].should == subject.send( attribute )
            end
        end

        it "includes 'options'" do
            data['options'].should ==
                Arachni::Options.update( subject.options ).to_rpc_data
        end

        it "includes 'plugins'" do
            options_1 = data['plugins'].map { |name, d| d[:options] }
            options_2 = subject.plugins.map { |name, d| d[:options].map(&:to_rpc_data) }

            info_1 = data['plugins'].each { |name, d| d.delete :options }
            info_2 = subject.plugins.each { |name, d| d.delete :options }

            info_1.should == info_2
            options_1.should == options_2
        end

        it "includes 'issues'" do
            data['issues'].should == subject.issues.map(&:to_rpc_data)
        end

        %w(start_datetime finish_datetime).each do |attribute|
            it "includes '#{attribute}'" do
                data[attribute].should == subject.send( attribute ).to_s
            end
        end
    end

    describe '.from_rpc_data' do
        let(:subject) { report }

        let(:restored) { described_class.from_rpc_data data }
        let(:data) { Arachni::RPC::Serializer.rpc_data( subject ) }

        %w(sitemap issues plugins version).each do |attribute|
            it "restores '#{attribute}'" do
                restored.send( attribute ).should == subject.send( attribute )
            end
        end

        it "restores 'options'" do
            restored.options.delete :input
            subject.options.delete :input

            restored.options.should == subject.options
        end

        %w(start_datetime finish_datetime).each do |attribute|
            it "restores '#{attribute}'" do
                restored.send( attribute ).should be_kind_of Time
                restored.send( attribute ).to_s.should == subject.send( attribute ).to_s
            end
        end
    end

    describe '#version' do
        it 'returns the version number' do
            report.version.should == Arachni::VERSION
        end
    end

    describe '#url' do
        it 'returns the targeted URL' do
            report.url.should == report.options[:url]
        end
    end

    describe '#options' do
        it 'returns Arachni::Options as a hash' do
           report.options.should == Arachni::Options.to_hash
        end

        it 'defaults to Arachni::Options#to_hash' do
            new  = described_class.new.options
            hash = Arachni::Options.to_hash

            new.delete :input
            hash.delete :input

            new.should == hash
        end
    end

    describe '#sitemap' do
        it 'returns the sitemap' do
            report.sitemap.should == {@opts.url.to_s => 200}
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
            report.issues.should be_any

            report.issues.each do |issue|
                report.issue_by_digest( issue.digest ).should == issue
            end
        end
    end

    describe '#plugins' do
        it 'returns the plugin results' do
            report.plugins.should == Factory[:report_data][:plugins]
        end
    end

    describe '#start_datetime' do
        it 'returns a Time object' do
            report.start_datetime.should be_kind_of Time
        end
        context 'when no start datetime info has been provided' do
            it 'falls-back to Time.now' do
                report_empty.start_datetime.should be_kind_of Time
            end
        end
    end

    describe '#finish_datetime' do
        it 'returns a Time object' do
            report.finish_datetime.should be_kind_of Time
        end
        it 'returns the start finish of the scan' do
            report.finish_datetime.to_s.should ==
                Factory[:report_data][:finish_datetime].to_s
        end
        context 'when no start datetime info has been provided' do
            it 'falls-back to Time.now' do
                report_empty.finish_datetime.should be_kind_of Time
            end
        end
    end

    describe '#delta_time' do
        it 'returns the time difference between start and finish time' do
            report.delta_time.should == '02:46:40'
        end
        context 'when no #finish_datetime has been provided' do
            it 'uses Time.now for the calculation' do
                report_empty.start_datetime = Time.now - 2000
                report_empty.delta_time.to_s.should == '00:33:19'
            end
        end
    end

    describe '.read_summary' do
        it 'returns summary' do
            @report_file = report.save
            described_class.read_summary( @report_file ).should ==
                Arachni::RPC::Serializer.load( Arachni::RPC::Serializer.dump( report.summary ) )
        end
    end

    describe '#save' do
        it 'dumps the object to a file' do
            @report_file = report.save

            described_class.load( @report_file ).should == report
        end

        context 'when given a location' do
            context 'which is a filepath' do
                it 'saves the object to that file' do
                    @report_file = 'report'
                    report.save( @report_file )

                    described_class.load( @report_file ).should == report
                end
            end

            context 'which is a directory' do
                it 'saves the object under that directory' do
                    directory = Dir.tmpdir
                    @report_file = report.save( directory )

                    described_class.load( @report_file ).should == report
                end
            end
        end
    end

    describe '#to_afr' do
        it 'returns the object in AFR format' do
            @report_file = report.save

            IO.binread( @report_file ).should == report.to_afr
        end
    end

    describe '#to_h' do
        it 'returns the object as a hash' do
            report.to_h.should == {
                version:         report.version,
                options:         Arachni::Options.hash_to_rpc_data( report.options ),
                sitemap:         report.sitemap,
                start_datetime:  report.start_datetime.to_s,
                finish_datetime: report.finish_datetime.to_s,
                delta_time:      report.delta_time,
                issues:          report.issues.map(&:to_h),
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
                                type:        :multiple_choice
                            }
                        ]
                    }
                }
            }
        end
    end

    describe '#to_hash' do
        it 'alias of #to_h' do
            report.to_h.should == report.to_hash
        end
    end

    describe '#==' do
        context 'when the reports are equal' do
            it 'returns true' do
                report.deep_clone.should == report
            end
        end
        context 'when the reports are not equal' do
            it 'returns false' do
                a = report.deep_clone
                a.options[:url] = 'http://stuff/'
                a.should_not == report
            end
        end
    end

end
