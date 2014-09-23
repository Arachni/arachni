require 'spec_helper'

describe Arachni::OptionGroups::Paths do

    before :all do
        @created_resources = []
    end

    after :each do
        ENV['ARACHNI_FRAMEWORK_LOGDIR'] = nil

        (@created_resources + [paths_config_file]).each do |r|
            FileUtils.rm_rf r
        end
    end

    let(:paths_config_file) { "#{Dir.tmpdir}/paths-#{Process.pid}.yml" }

    %w(root arachni components logs checks reporters plugins services
        path_extractors fingerprinters lib support mixins snapshots).each do |method|

        describe "##{method}" do
            it 'points to an existing directory' do
                File.exists?( subject.send method ).should be_true
            end
        end

        it { should respond_to method }
        it { should respond_to "#{method}=" }
    end

    describe '#logs' do
        it 'returns the default location' do
            subject.logs.should == "#{subject.root}logs/"
        end

        context 'when the ARACHNI_FRAMEWORK_LOGDIR environment variable' do
            it 'returns its value' do
                ENV['ARACHNI_FRAMEWORK_LOGDIR'] = 'test'
                subject.logs.should == 'test/'
            end
        end

        context "when #{described_class}.config['framework']['logs']" do
            it 'returns its value' do
                described_class.stub(:config) do
                    {
                        'framework' => {
                            'logs' => 'logs-stuff/'
                        }
                    }
                end

                described_class.new.logs.should == 'logs-stuff/'
            end
        end
    end

    describe '#snapshots' do
        it 'returns the default location' do
            subject.snapshots.should == "#{subject.root}snapshots/"
        end

        context "when #{described_class}.config['framework']['snapshots']" do
            it 'returns its value' do
                described_class.stub(:config) do
                    {
                        'framework' => {
                            'snapshots' => 'snapshots-stuff/'
                        }
                    }
                end

                described_class.new.snapshots.should == 'snapshots-stuff/'
            end
        end
    end

    describe '.config' do
        let(:config) { described_class.config }

        it 'expands ~ to $HOME' do
            yaml = {
                'stuff' => {
                    'blah' => "~/foo-#{Process.pid}/"
                }
            }.to_yaml

            described_class.stub(:paths_config_file) { paths_config_file }
            IO.write( described_class.paths_config_file, yaml )
            described_class.clear_config_cache

            @created_resources << described_class.config['stuff']['blah']

            described_class.config['stuff']['blah'].should == "#{ENV['HOME']}/foo-#{Process.pid}/"
        end

        it 'appends / to paths' do
            dir = "#{Dir.tmpdir}/foo-#{Process.pid}"
            yaml = {
                'stuff' => {
                    'blah' => dir
                }
            }.to_yaml

            described_class.stub(:paths_config_file) { paths_config_file }
            IO.write( described_class.paths_config_file, yaml )
            described_class.clear_config_cache

            @created_resources << described_class.config['stuff']['blah']

            described_class.config['stuff']['blah'].should == "#{dir}/"
        end

        it 'creates the given directories' do
            dir = "#{Dir.tmpdir}/foo/stuff-#{Process.pid}"
            yaml = {
                'stuff' => {
                    'blah' => dir
                }
            }.to_yaml

            described_class.stub(:paths_config_file) { paths_config_file }
            IO.write( described_class.paths_config_file, yaml )
            described_class.clear_config_cache

            @created_resources << dir

            File.exist?( dir ).should be_false
            described_class.config
            File.exist?( dir ).should be_true
        end
    end

end
