shared_examples_for 'locatable_dom' do

    describe '#locate' do
        it 'locates the live element' do
            called = false
            subject.with_browser do |browser|
                subject.browser = browser
                browser.load subject.page

                element = subject.locate
                expect(element).to be_kind_of Selenium::WebDriver::Element
                called = true
            end

            subject.auditor.browser_cluster.wait
            expect(called).to be_truthy
        end
    end

end
