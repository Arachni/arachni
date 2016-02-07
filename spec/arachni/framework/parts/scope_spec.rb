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

                        expect(f.page_limit_reached?).to be_falsey
                        f.run
                        expect(f.page_limit_reached?).to be_truthy

                        expect(f.sitemap.size).to eq(10)
                    end
                end
            end

            context 'not been reached' do
                it 'returns false' do
                    Arachni::Framework.new do |f|
                        f.options.url = web_server_url_for :framework
                        f.options.audit.elements :links
                        f.options.scope.page_limit = 100

                        f.checks.load :signature

                        expect(f.page_limit_reached?).to be_falsey
                        f.run
                        expect(f.page_limit_reached?).to be_falsey
                    end
                end
            end

            context 'not been set' do
                it 'returns false' do
                    Arachni::Framework.new do |f|
                        f.options.url = web_server_url_for :framework
                        f.options.audit.elements :links

                        f.checks.load :signature

                        expect(f.page_limit_reached?).to be_falsey
                        f.run
                        expect(f.page_limit_reached?).to be_falsey
                    end
                end
            end
        end
    end

    describe '#accepts_more_pages?' do
        context 'when #page_limit_reached? and #crawl?' do
            it 'return true' do
                allow(subject).to receive(:page_limit_reached?) { false }
                allow(subject).to receive(:crawl?) { true }

                expect(subject.accepts_more_pages?).to be_truthy
            end
        end

        context 'when #page_limit_reached?' do
            context 'true' do
                it 'returns false' do
                    allow(subject).to receive(:page_limit_reached?) { true }
                    expect(subject.accepts_more_pages?).to be_falsey
                end
            end
        end

        context 'when #crawl?' do
            context 'false' do
                it 'returns false' do
                    allow(subject).to receive(:crawl?) { false }
                    expect(subject.accepts_more_pages?).to be_falsey
                end
            end
        end
    end

end
