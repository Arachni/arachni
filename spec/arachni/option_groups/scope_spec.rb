require 'spec_helper'

describe Arachni::OptionGroups::Scope do
    include_examples 'option_group'
    subject { described_class.new }

    %w(directory_depth_limit dom_depth_limit page_limit restrict_paths extend_paths
        redundant_path_patterns auto_redundant_paths include_path_patterns
        exclude_path_patterns exclude_content_patterns include_subdomains https_only
        url_rewrites exclude_binaries exclude_file_extensions dom_event_limit
    ).each do |method|
        it { is_expected.to respond_to method }
        it { is_expected.to respond_to "#{method}=" }
    end

    describe '#url_rewrites' do
        it 'converts the keys to Regexp' do
            subject.url_rewrites = {
                '/article/(\d+)' => 'articles?id=\1'
            }

            expect(subject.url_rewrites.to_s).to eq({
                /\/article\/(\d+)/i => 'articles?id=\1'
            }.to_s)
        end
    end

    describe '#https_only?' do
        describe 'when #https_only has been enabled' do
            it 'returns true' do
                subject.https_only = true
                expect(subject.https_only?).to be_truthy
            end
        end
        describe 'when #https_only has been disabled' do
            it 'returns false' do
                subject.https_only = false
                expect(subject.https_only?).to be_falsey
            end
        end
        describe 'by default' do
            it 'returns false' do
                expect(subject.https_only?).to be_falsey
            end
        end
    end

    describe '#auto_redundant?' do
        describe 'when #auto_redundant_paths has been enabled' do
            it 'returns true' do
                subject.auto_redundant_paths = 10
                expect(subject.auto_redundant?).to be_truthy
            end
        end
        describe 'when #auto_redundant_paths has been disabled' do
            it 'returns false' do
                subject.auto_redundant_paths = nil
                expect(subject.auto_redundant?).to be_falsey
            end
        end
        describe 'by default' do
            it 'returns false' do
                expect(subject.auto_redundant?).to be_falsey
            end
        end
    end

    describe '#redundant_path_patterns=' do
        it 'converts its param to properly typed filters' do
            subject.redundant_path_patterns = { /pattern/ => '45', 'regexp' => 39 }
            expect(subject.redundant_path_patterns).to eq({
                /pattern/ => 45,
                /regexp/i => 39
            })
        end
    end

    describe '#do_not_crawl' do
        it 'sets the page_limit to 0' do
            subject.do_not_crawl
            expect(subject.page_limit).to eq(0)
        end
    end

    describe '#crawl' do
        it 'sets the page_limit to < 0' do
            subject.crawl
            expect(subject.crawl?).to be_truthy
            !expect(subject.page_limit).to be_nil
        end
    end

    describe '#crawl?' do
        context 'by default' do
            it 'returns true' do
                expect(subject.crawl?).to be_truthy
            end
        end
        context 'when crawling is enabled' do
            it 'returns true' do
                subject.do_not_crawl
                expect(subject.crawl?).to be_falsey
                subject.crawl
                expect(subject.crawl?).to be_truthy
            end
        end
        context 'when crawling is disabled' do
            it 'returns false' do
                expect(subject.crawl?).to be_truthy
                subject.do_not_crawl
                expect(subject.crawl?).to be_falsey
            end
        end
    end

    describe '#page_limit_reached?' do
        context 'when #page_limit has' do
            context 'not been set' do
                it 'returns false' do
                    expect(subject.page_limit_reached?( 44 )).to be_falsey
                end
            end

            context 'not been reached' do
                it 'returns false' do
                    subject.page_limit = 5
                    expect(subject.page_limit_reached?( 2 )).to be_falsey
                end
            end

            context 'been reached' do
                it 'returns true' do
                    subject.page_limit = 5
                    expect(subject.page_limit_reached?( 5 )).to be_truthy
                    expect(subject.page_limit_reached?( 6 )).to be_truthy
                end
            end
        end
    end

    describe '#dom_event_limit_reached?' do
        context 'when #page_limit has' do
            context 'not been set' do
                it 'returns false' do
                    expect(subject.dom_event_limit_reached?( 44 )).to be_falsey
                end
            end

            context 'not been reached' do
                it 'returns false' do
                    subject.dom_event_limit = 5
                    expect(subject.dom_event_limit_reached?( 2 )).to be_falsey
                end
            end

            context 'been reached' do
                it 'returns true' do
                    subject.dom_event_limit = 5
                    expect(subject.dom_event_limit_reached?( 5 )).to be_truthy
                    expect(subject.dom_event_limit_reached?( 6 )).to be_truthy
                end
            end
        end
    end

    describe '#restrict_paths=' do
        it 'converts its param to an array of strings' do
            restrict_paths = %w(my_restrict_paths my_other_restrict_paths)

            subject.restrict_paths = restrict_paths.first
            expect(subject.restrict_paths).to eq([restrict_paths.first])

            subject.restrict_paths = restrict_paths
            expect(subject.restrict_paths).to eq(restrict_paths)
        end
    end

    describe '#extend_paths=' do
        it 'converts its param to an array of strings' do
            extend_paths = %w(my_extend_paths my_other_extend_paths)

            subject.extend_paths = extend_paths.first
            expect(subject.extend_paths).to eq([extend_paths.first])

            subject.extend_paths = extend_paths
            expect(subject.extend_paths).to eq(extend_paths)
        end
    end

    describe '#include_path_patterns=' do
        it 'converts its param to an Array of Regexp' do
            include = %w(my_include my_other_include)

            subject.include_path_patterns = /test/
            expect(subject.include_path_patterns).to eq([/test/])

            subject.include_path_patterns = include.first
            expect(subject.include_path_patterns).to eq([Regexp.new( include.first, Regexp::IGNORECASE )])

            subject.include_path_patterns = include
            expect(subject.include_path_patterns).to eq(include.map { |p| Regexp.new( p, Regexp::IGNORECASE ) })
        end
    end

    describe '#exclude_file_extensions=' do
        it 'converts its param to an array of strings' do
            exclude_extensions = %w(my_extend_paths my_other_extend_paths)

            subject.exclude_file_extensions = exclude_extensions.first
            expect(subject.exclude_file_extensions).to eq(Set.new([exclude_extensions.first]))

            subject.exclude_file_extensions = exclude_extensions
            expect(subject.exclude_file_extensions).to eq(Set.new(exclude_extensions))
        end
    end

    describe '#exclude_path_patterns=' do
        it 'converts its param to an Array of Regexp' do
            exclude = %w(my_exclude my_other_exclude)

            subject.exclude_path_patterns= /test/
            expect(subject.exclude_path_patterns).to eq([/test/])

            subject.exclude_path_patterns= exclude.first
            expect(subject.exclude_path_patterns).to eq([Regexp.new( exclude.first, Regexp::IGNORECASE )])

            subject.exclude_path_patterns= exclude
            expect(subject.exclude_path_patterns).to eq(exclude.map { |p| Regexp.new( p, Regexp::IGNORECASE ) })
        end
    end

    describe '#exclude_content_patterns=' do
        it 'converts its param to an Array of Regexp' do
            exclude_pages = %w(my_ignore my_other_ignore)

            subject.exclude_content_patterns = /test/
            expect(subject.exclude_content_patterns).to eq([/test/])

            subject.exclude_content_patterns = exclude_pages.first
            expect(subject.exclude_content_patterns).to eq([Regexp.new( exclude_pages.first, Regexp::IGNORECASE )])

            subject.exclude_content_patterns = exclude_pages
            expect(subject.exclude_content_patterns).to eq(exclude_pages.map { |p| Regexp.new( p, Regexp::IGNORECASE ) })
        end
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "converts 'redundant_path_patterns' to strings" do
            subject.redundant_path_patterns = { /redundant_path_patterns/ => 1 }

            expect(data['redundant_path_patterns']).to eq({ 'redundant_path_patterns' => 1 })
        end

        it "converts 'url_rewrites' to strings" do
            subject.url_rewrites = { /url_rewrites/ => 'test' }

            expect(data['url_rewrites']).to eq({ 'url_rewrites' => 'test' })
        end

        it "converts 'exclude_file_extensions' to Array of string" do
            subject.exclude_file_extensions = Set.new( ['stuff'] )

            expect(data['exclude_file_extensions']).to eq(['stuff'])
        end

        %w(exclude_path_patterns exclude_content_patterns include_path_patterns).each do |k|
            it "converts '#{k}' to strings" do
                values = [/#{k}/]
                subject.send( "#{k}=", values )

                expect(data[k]).to eq([/#{k}/.source])
            end
        end
    end

end
