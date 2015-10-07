module PageHelpers
    Arachni::Page::ELEMENTS.each do |element|
        element = element.to_s[0...-1]

        define_method "find_#{element}_with_input_from_pages" do |pages, input_name|
            send( "find_page_with_#{element}_with_input", pages, input_name ).
                send("#{element}s").find { |e| e.inputs.include? input_name }
        end

        define_method "find_page_with_#{element}_with_input" do |pages, input_name|
            pages.find do |page|
                page.send("#{element}s").find { |e| e.inputs.include? input_name }
            end
        end

        define_method "pages_should_have_#{element}_with_input" do |pages, input_name|
            expect(send( "find_page_with_#{element}_with_input", pages, input_name )).to be_truthy
        end

        define_method "pages_should_not_have_#{element}_with_input" do |pages, input_name|
            expect(send( "find_page_with_#{element}_with_input", pages, input_name )).to be_falsey
        end

    end
end

extend PageHelpers
