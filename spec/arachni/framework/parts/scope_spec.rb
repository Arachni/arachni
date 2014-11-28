require 'spec_helper'

describe Arachni::Framework::Parts::Scope do
    include_examples 'framework'

    describe '#page_limit_reached?' do
        context "when the #{Arachni::OptionGroups::Scope}#page_limit has" do
            context 'been reached' do
                it 'returns true' do
                    Arachni::Framework.new do |f|
                        f.options.url = web_server_url_for :framework_multi
                        f.options.audit.elements :links
                        f.options.scope.page_limit = 10

                        f.page_limit_reached?.should be_false
                        f.run
                        f.page_limit_reached?.should be_true

                        f.sitemap.size.should == 10
                    end
                end
            end

            context 'not been reached' do
                it 'returns false' do
                    Arachni::Framework.new do |f|
                        f.options.url = web_server_url_for :framework
                        f.options.audit.elements :links
                        f.options.scope.page_limit = 100

                        f.checks.load :taint

                        f.page_limit_reached?.should be_false
                        f.run
                        f.page_limit_reached?.should be_false
                    end
                end
            end

            context 'not been set' do
                it 'returns false' do
                    Arachni::Framework.new do |f|
                        f.options.url = web_server_url_for :framework
                        f.options.audit.elements :links

                        f.checks.load :taint

                        f.page_limit_reached?.should be_false
                        f.run
                        f.page_limit_reached?.should be_false
                    end
                end
            end
        end
    end

    describe '#accepts_more_pages?' do
        context 'when #page_limit_reached? and #crawl?' do
            it 'return true' do
                subject.stub(:page_limit_reached?) { false }
                subject.stub(:crawl?) { true }

                subject.accepts_more_pages?.should be_true
            end
        end

        context 'when #page_limit_reached?' do
            context true do
                it 'returns false' do
                    subject.stub(:page_limit_reached?) { true }
                    subject.accepts_more_pages?.should be_false
                end
            end
        end

        context 'when #crawl?' do
            context false do
                it 'returns false' do
                    subject.stub(:crawl?) { false }
                    subject.accepts_more_pages?.should be_false
                end
            end
        end
    end

end
