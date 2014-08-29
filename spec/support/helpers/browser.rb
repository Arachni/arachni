def browser_explore_check_pages( pages )
    pages_should_have_form_with_input pages, 'by-ajax'
    pages_should_have_form_with_input pages, 'from-post-ajax'
    pages_should_have_form_with_input pages, 'ajax-token'
    pages_should_have_form_with_input pages, 'href-post-name'
end
