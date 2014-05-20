require 'spec_helper'

describe Arachni::OptionGroups::Scope do
    include_examples 'option_group'
    subject { described_class.new }

    %w(directory_depth_limit dom_depth_limit page_limit restrict_paths
        restrict_paths_filepath extend_paths extend_paths_filepath
        redundant_path_patterns auto_redundant_paths include_path_patterns
        exclude_path_patterns exclude_page_patterns include_subdomains https_only
        link_rewrites
    ).each do |method|
        it { should respond_to method }
        it { should respond_to "#{method}=" }
    end

    describe '#link_rewrites' do
        it 'converts the keys to Regexp' do
            subject.link_rewrites = {
                '/article/(\d+)' => 'articles?id=\1'
            }

            subject.link_rewrites.should == {
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

    describe '#auto_redundant_path?' do
        context 'when #auto_redundant_paths limit has been reached' do
            it 'returns true' do
                path = 'http://test.com/?test=2&test2=2'

                subject.auto_redundant_paths = 10
                subject.auto_redundant_path?( path ).should be_false
                9.times do
                    subject.auto_redundant_path?( path ).should be_false
                end

                subject.auto_redundant_path?( path ).should be_true
            end

            context 'when passed a block' do
                it 'calls it and passes the counter' do
                    path = 'http://test.com/?test=2&test2=2'

                    subject.auto_redundant_paths = 1

                    counter = 0
                    i       = 0
                    subject.auto_redundant_path?( path ) do |c|
                        counter = c
                        i       += 1
                    end.should be_false

                    counter.should == 0
                    i.should       == 0

                    subject.auto_redundant_path?( path ) do |c|
                        counter = c
                        i       += 1
                    end.should be_true

                    counter.should == 1
                    i.should       == 1

                    subject.auto_redundant_path?( path ) do |c|
                        counter = c
                        i       += 1
                    end.should be_true

                    counter.should == 1
                    i.should       == 2
                end
            end
        end

        describe 'by default' do
            it 'returns false' do
                path = 'http://test.com/?test=2&test2=2'
                subject.auto_redundant_path?( path ).should be_false
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

    describe '#exclude_page_patterns=' do
        it 'converts its param to an Array of Regexp' do
            exclude_pages = %w(my_ignore my_other_ignore)

            subject.exclude_page_patterns = /test/
            subject.exclude_page_patterns.should == [/test/]

            subject.exclude_page_patterns = exclude_pages.first
            subject.exclude_page_patterns.should == [Regexp.new( exclude_pages.first )]

            subject.exclude_page_patterns = exclude_pages
            subject.exclude_page_patterns.should == exclude_pages.map { |p| Regexp.new( p ) }
        end
    end

    describe '#exclude_page?' do
        context 'when the string matches one of the #exclude_page_patterns' do
            it 'returns true' do
                subject.exclude_page_patterns = /test/
                subject.exclude_page?( 'this is a test test test' ).should be_true
            end
        end
        context 'when the string does not match one of the #exclude_page_patterns' do
            it 'returns false' do
                subject.exclude_page_patterns = /test/
                subject.exclude_page?( 'this is a blah blah blah' ).should be_false
            end
        end
    end
end
