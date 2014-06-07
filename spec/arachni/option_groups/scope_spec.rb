require 'spec_helper'

describe Arachni::OptionGroups::Scope do
    include_examples 'option_group'
    subject { described_class.new }

    %w(directory_depth_limit dom_depth_limit page_limit restrict_paths extend_paths
        redundant_path_patterns auto_redundant_paths include_path_patterns
        exclude_path_patterns exclude_content_patterns include_subdomains https_only
        url_rewrites exclude_binaries
    ).each do |method|
        it { should respond_to method }
        it { should respond_to "#{method}=" }
    end

    describe '#url_rewrites' do
        it 'converts the keys to Regexp' do
            subject.url_rewrites = {
                '/article/(\d+)' => 'articles?id=\1'
            }

            subject.url_rewrites.should == {
                /\/article\/(\d+)/ => 'articles?id=\1'
            }
        end
    end

    describe '#https_only?' do
        describe 'when #https_only has been enabled' do
            it 'returns true' do
                subject.https_only = true
                subject.https_only?.should be_true
            end
        end
        describe 'when #https_only has been disabled' do
            it 'returns false' do
                subject.https_only = false
                subject.https_only?.should be_false
            end
        end
        describe 'by default' do
            it 'returns false' do
                subject.https_only?.should be_false
            end
        end
    end

    describe '#auto_redundant?' do
        describe 'when #auto_redundant_paths has been enabled' do
            it 'returns true' do
                subject.auto_redundant_paths = 10
                subject.auto_redundant?.should be_true
            end
        end
        describe 'when #auto_redundant_paths has been disabled' do
            it 'returns false' do
                subject.auto_redundant_paths = nil
                subject.auto_redundant?.should be_false
            end
        end
        describe 'by default' do
            it 'returns false' do
                subject.auto_redundant?.should be_false
            end
        end
    end

    describe '#redundant_path_patterns=' do
        it 'converts its param to properly typed filters' do
            subject.redundant_path_patterns = { /pattern/ => '45', 'regexp' => 39 }
            subject.redundant_path_patterns.should == {
                /pattern/ => 45,
                /regexp/  => 39
            }
        end
    end

    describe '#do_not_crawl' do
        it 'sets the page_limit to 0' do
            subject.do_not_crawl
            subject.page_limit.should == 0
        end
    end

    describe '#crawl' do
        it 'sets the page_limit to < 0' do
            subject.crawl
            subject.crawl?.should be_true
            !subject.page_limit.should be_nil
        end
    end

    describe '#crawl?' do
        context 'by default' do
            it 'returns true' do
                subject.crawl?.should be_true
            end
        end
        context 'when crawling is enabled' do
            it 'returns true' do
                subject.do_not_crawl
                subject.crawl?.should be_false
                subject.crawl
                subject.crawl?.should be_true
            end
        end
        context 'when crawling is disabled' do
            it 'returns false' do
                subject.crawl?.should be_true
                subject.do_not_crawl
                subject.crawl?.should be_false
            end
        end
    end

    describe '#page_limit_reached?' do
        context 'when #page_limit has' do
            context 'not been set' do
                it 'returns false' do
                    subject.page_limit_reached?( 44 ).should be_false
                end
            end

            context 'not been reached' do
                it 'returns false' do
                    subject.page_limit = 5
                    subject.page_limit_reached?( 2 ).should be_false
                end
            end

            context 'been reached' do
                it 'returns true' do
                    subject.page_limit = 5
                    subject.page_limit_reached?( 5 ).should be_true
                    subject.page_limit_reached?( 6 ).should be_true
                end
            end
        end
    end

    describe '#restrict_paths=' do
        it 'converts its param to an array of strings' do
            restrict_paths = %w(my_restrict_paths my_other_restrict_paths)

            subject.restrict_paths = restrict_paths.first
            subject.restrict_paths.should == [restrict_paths.first]

            subject.restrict_paths = restrict_paths
            subject.restrict_paths.should == restrict_paths
        end
    end

    describe '#extend_paths=' do
        it 'converts its param to an array of strings' do
            extend_paths = %w(my_extend_paths my_other_extend_paths)

            subject.extend_paths = extend_paths.first
            subject.extend_paths.should == [extend_paths.first]

            subject.extend_paths = extend_paths
            subject.extend_paths.should == extend_paths
        end
    end

    describe '#include_path_patterns=' do
        it 'converts its param to an Array of Regexp' do
            include = %w(my_include my_other_include)

            subject.include_path_patterns = /test/
            subject.include_path_patterns.should == [/test/]

            subject.include_path_patterns = include.first
            subject.include_path_patterns.should == [Regexp.new( include.first )]

            subject.include_path_patterns = include
            subject.include_path_patterns.should == include.map { |p| Regexp.new( p ) }
        end
    end

    describe '#exclude_path_patterns=' do
        it 'converts its param to an Array of Regexp' do
            exclude = %w(my_exclude my_other_exclude)

            subject.exclude_path_patterns= /test/
            subject.exclude_path_patterns.should == [/test/]

            subject.exclude_path_patterns= exclude.first
            subject.exclude_path_patterns.should == [Regexp.new( exclude.first )]

            subject.exclude_path_patterns= exclude
            subject.exclude_path_patterns.should == exclude.map { |p| Regexp.new( p ) }
        end
    end

    describe '#exclude_content_patterns=' do
        it 'converts its param to an Array of Regexp' do
            exclude_pages = %w(my_ignore my_other_ignore)

            subject.exclude_content_patterns = /test/
            subject.exclude_content_patterns.should == [/test/]

            subject.exclude_content_patterns = exclude_pages.first
            subject.exclude_content_patterns.should == [Regexp.new( exclude_pages.first )]

            subject.exclude_content_patterns = exclude_pages
            subject.exclude_content_patterns.should == exclude_pages.map { |p| Regexp.new( p ) }
        end
    end

    describe '#to_rpc_data' do
        let(:data) { subject.to_rpc_data }

        it "converts 'redundant_path_patterns' to strings" do
            values = { /redundant_path_patterns/ => 1 }
            subject.redundant_path_patterns = values

            data['redundant_path_patterns'].should == values.stringify
        end

        it "converts 'url_rewrites' to strings" do
            values = { /url_rewrites/ => 'test' }
            subject.url_rewrites = values

            data['url_rewrites'].should == values.stringify
        end

        %w(exclude_path_patterns exclude_content_patterns include_path_patterns).each do |k|
            it "converts '#{k}' to strings" do
                values = [/#{k}/]
                subject.send( "#{k}=", values )

                data[k].should == [/#{k}/.to_s]
            end
        end
    end

end
