def find_form_with_input_from_pages( pages, input_name )
    find_page_with_form_with_input( pages, input_name ).
        forms.find { |form| form.inputs.include? input_name }
end

def find_page_with_form_with_input( pages, input_name )
    pages.find do |page|
        page.forms.find { |form| form.inputs.include? input_name }
    end
end

def pages_should_have_form_with_input( pages, input_name )
    find_page_with_form_with_input( pages, input_name ).should be_true
end

def pages_should_not_have_form_with_input( pages, input_name )
    find_page_with_form_with_input( pages, input_name ).should be_false
end
