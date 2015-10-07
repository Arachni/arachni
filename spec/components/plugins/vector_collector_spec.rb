require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        options.url = url
        options.audit.elements :cookies, :links, :forms
    end

    def results
        yaml_load <<YAML
---
__URL__:
- class: Arachni::Element::Link
  type: :link
  url: __URL__
  inputs:
    link_input: blah
  action: __URL__link
  method: get
  source: <a href="/link?link_input=blah">A link</a>
- class: Arachni::Element::Form
  type: :form
  url: __URL__
  inputs:
    form-input: ''
  action: __URL__
  method: post
  source: |-
    <form method="post">
                <input name="form-input">
            </form>
- class: Arachni::Element::Cookie
  type: :cookie
  url: __URL__
  inputs:
    cookie1: val1
  action: __URL__
  method: get
  source: cookie1=val1; domain=127.0.0.2; path=/; HttpOnly
__URL__link?link_input=blah:
- class: Arachni::Element::Cookie
  type: :cookie
  url: __URL__
  inputs:
    cookie1: val1
  action: __URL__link?link_input=blah
  method: get
  source: cookie1=val1; domain=127.0.0.2; path=/; HttpOnly
YAML
    end

    easy_test
end
