require 'spec_helper'

describe Arachni::Framework::Parts::Browser do
    include_examples 'framework'

    describe '#browser_cluster' do
        context 'when #use_browsers? is' do
            context true do
                before do
                    subject.stub(:use_browsers?) { true }
                end

                it "returns #{Arachni::BrowserCluster}" do
                    subject.browser_cluster.should be_kind_of Arachni::BrowserCluster
                end
            end

            context false do
                before do
                    subject.stub(:use_browsers?) { false }
                end

                it 'returns nil' do
                    subject.browser_cluster.should be_nil
                end
            end
        end
    end

    describe '#use_browsers?' do
        context "when #{Arachni::OptionGroups::BrowserCluster}#pool_size is" do
            context 0 do
                before do
                    subject.options.browser_cluster.pool_size = 0
                end

                it 'returns false' do
                    subject.use_browsers?.should be_false
                end
            end

            context '> 0' do
                before do
                    subject.options.browser_cluster.pool_size = 1
                end

                it 'returns true' do
                    subject.use_browsers?.should be_true
                end
            end
        end

        context "when #{Arachni::OptionGroups::Scope}#dom_depth_limit is" do
            context 0 do
                before do
                    subject.options.scope.dom_depth_limit = 0
                end

                it 'returns false' do
                    subject.use_browsers?.should be_false
                end
            end

            context '> 0' do
                before do
                    subject.options.scope.dom_depth_limit = 1
                end

                it 'returns true' do
                    subject.use_browsers?.should be_true
                end
            end
        end

        context 'when #host_has_browser? is' do
            context true do
                before do
                    subject.stub(:use_browsers?) { true }
                end

                it 'returns true' do
                    subject.use_browsers?.should be_true
                end
            end

            context false do
                before do
                    subject.stub(:host_has_browser?) { false }
                end

                it 'returns false' do
                    subject.use_browsers?.should be_false
                end
            end
        end
    end

    describe '#host_has_browser?' do
        context "when #{Arachni::Browser}.has_executable? is" do
            context true do
                before do
                    Arachni::Browser.stub(:has_executable?) { true }
                end

                it 'returns true' do
                    subject.host_has_browser?.should be_true
                end
            end

            context false do
                before do
                    Arachni::Browser.stub(:has_executable?) { false }
                end

                it 'returns false' do
                    subject.host_has_browser?.should be_false
                end
            end
        end
    end

    describe '#apply_dom_metadata' do
        let(:page) { Factory[:page] }
        let(:browser_page) { Factory[:page] }
        let(:check) { subject.checks[:taint] }

        before do
            subject.checks.load :taint

            subject.browser.stub(:to_page) { browser_page }
            Arachni::Check::Auditor.stub(:check?) { true }
            page.stub(:has_script?) { true }
            page.dom.stub(:depth) { 0 }
        end

        it 'returns true' do
            subject.apply_dom_metadata( page ).should be_true
        end

        it 'applies DOM metadata' do
            page.should receive(:import_metadata).with( browser_page, :skip_dom )

            subject.apply_dom_metadata( page )
        end

        it 'clears the #browser buffers' do
            subject.browser.should receive(:clear_buffers)

            subject.apply_dom_metadata( page )
        end

        context "when #{Arachni::Page::DOM}#depth is" do
            context 0 do
                before do
                    page.dom.stub(:depth) { 0 }
                end

                it 'returns true' do
                    subject.apply_dom_metadata( page ).should be_true
                end
            end

            context '> 0' do
                before do
                    page.dom.stub(:depth) { 1 }
                end

                it 'returns false' do
                    subject.apply_dom_metadata( page ).should be_false
                end
            end
        end

        context "when #{Arachni::Page}#has_script? is" do
            context false do
                before do
                    page.stub(:has_script?) { false }
                end

                it 'returns false' do
                    subject.apply_dom_metadata( page ).should be_false
                end
            end

            context true do
                before do
                    page.stub(:has_script?) { true }
                end

                it 'returns true' do
                    subject.apply_dom_metadata( page ).should be_true
                end
            end
        end

        context 'when #use_browsers? is' do
            context false do
                before do
                    subject.stub(:use_browsers?) { false }
                end

                it 'returns false' do
                    subject.apply_dom_metadata( page ).should be_false
                end
            end

            context true do
                before do
                    subject.stub(:use_browsers?) { true }
                end

                it 'returns true' do
                    subject.apply_dom_metadata( page ).should be_true
                end
            end
        end

        context "when #{Arachni::Check::Auditor}.check? for [#{Arachni::Element::Form::DOM}, #{Arachni::Element::Cookie::DOM}] is" do
            before do
                check.should receive(:check?).with( page, [Arachni::Element::Form::DOM, Arachni::Element::Cookie::DOM] )
            end

            context false do
                before do
                    check.stub(:check?) { false }
                end

                it 'returns false' do
                    subject.apply_dom_metadata( page ).should be_false
                end
            end

            context true do
                before do
                    check.stub(:check?) { true }
                end

                it 'returns true' do
                    subject.apply_dom_metadata( page ).should be_true
                end
            end
        end

        context "when #{Arachni::Browser}#to_page returns" do
            context 'empty page' do
                before do
                    subject.browser.stub(:to_page) { Factory[:empty_page] }
                end

                it 'returns nil' do
                    subject.apply_dom_metadata( page ).should be_nil
                end
            end

            context 'valid page' do
                before do
                    subject.browser.stub(:to_page) { browser_page }
                end

                it 'returns true' do
                    subject.apply_dom_metadata( page ).should be_true
                end
            end
        end

        context "when #{Arachni::Browser}#to_page raises" do
            context "#{Selenium::WebDriver::Error::WebDriverError}" do
                before do
                    subject.browser.stub(:to_page) do
                        raise Selenium::WebDriver::Error::WebDriverError
                    end
                end

                it 'returns nil' do
                    subject.apply_dom_metadata( page ).should be_nil
                end
            end

            context "#{Watir::Exception::Error}" do
                before do
                    subject.browser.stub(:to_page) do
                        raise Watir::Exception::Error
                    end
                end

                it 'returns true' do
                    subject.apply_dom_metadata( page ).should be_nil
                end
            end
        end
    end
end
