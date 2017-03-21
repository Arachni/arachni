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

    let(:paths_config_file) { "#{Arachni::Options.paths.tmpdir}/paths-#{Process.pid}.yml" }

    %w(root arachni components logs checks reporters plugins services
        path_extractors fingerprinters lib support mixins snapshots).each do |method|

        describe "##{method}" do
            it 'points to an existing directory' do
                expect(File.exists?( subject.send method )).to be_truthy
            end
        end

        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end

    describe '#tmpdir' do
        context 'when no tmpdir has been specified via config' do
            it 'defaults to the OS tmpdir' do
                expect(subject.tmpdir).to eq Arachni.get_long_win32_filename( Dir.tmpdir )
            end
        end

        context "when #{described_class}.config['framework']['tmpdir']" do
            it 'returns its value' do
                allow(described_class).to receive(:config) do
                    {
                        'framework' => {
                            'tmpdir' => '/my/tmpdir/'
                        }
                    }
                end

                expect(subject.tmpdir).to eq('/my/tmpdir/')
            end
        end
    end

    describe '#logs' do
        it 'returns the default location' do
            expect(subject.logs).to eq("#{subject.root}logs/")
        end

        context 'when the ARACHNI_FRAMEWORK_LOGDIR environment variable' do
            it 'returns its value' do
                ENV['ARACHNI_FRAMEWORK_LOGDIR'] = 'test'
                expect(subject.logs).to eq('test/')
            end
        end

        context "when #{described_class}.config['framework']['logs']" do
            it 'returns its value' do
                allow(described_class).to receive(:config) do
                    {
                        'framework' => {
                            'logs' => 'logs-stuff/'
                        }
                    }
                end

                expect(described_class.new.logs).to eq('logs-stuff/')
            end
        end
    end

    describe '#snapshots' do
        it 'returns the default location' do
            expect(subject.snapshots).to eq("#{subject.root}snapshots/")
        end

        context "when #{described_class}.config['framework']['snapshots']" do
            it 'returns its value' do
                allow(described_class).to receive(:config) do
                    {
                        'framework' => {
                            'snapshots' => 'snapshots-stuff/'
                        }
                    }
                end

                expect(described_class.new.snapshots).to eq('snapshots-stuff/')
            end
        end
    end

    describe '.config' do
        let(:config) { described_class.config }

        it 'expands ~ to $HOME', if: !Arachni.windows? do
            yaml = {
                'stuff' => {
                    'blah' => "~/foo-#{Process.pid}/"
                }
            }.to_yaml

            allow(described_class).to receive(:paths_config_file) { paths_config_file }
            IO.write( described_class.paths_config_file, yaml )
            described_class.clear_config_cache

            @created_resources << described_class.config['stuff']['blah']

            expect(described_class.config['stuff']['blah']).to eq("#{ENV['HOME']}/foo-#{Process.pid}/")
        end

        it 'appends / to paths' do
            dir = "#{Dir.tmpdir}/foo-#{Process.pid}"
            yaml = {
                'stuff' => {
                    'blah' => dir
                }
            }.to_yaml

            allow(described_class).to receive(:paths_config_file) { paths_config_file }
            IO.write( described_class.paths_config_file, yaml )
            described_class.clear_config_cache

            @created_resources << described_class.config['stuff']['blah']

            expect(described_class.config['stuff']['blah']).to eq("#{dir}/")
        end

        it 'creates the given directories' do
            dir = "#{Dir.tmpdir}/foo/stuff-#{Process.pid}"
            yaml = {
                'stuff' => {
                    'blah' => dir
                }
            }.to_yaml

            allow(described_class).to receive(:paths_config_file) { paths_config_file }
            IO.write( described_class.paths_config_file, yaml )
            described_class.clear_config_cache

            @created_resources << dir

            expect(File.exist?( dir )).to be_falsey
            described_class.config
            expect(File.exist?( dir )).to be_truthy
        end
    end

end
