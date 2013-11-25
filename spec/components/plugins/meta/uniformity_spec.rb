require 'spec_helper'

describe name_from_filename do
    include_examples 'plugin'

    before( :all ) do
        @modname = 'Uber kewl check'
        @element = 'form'
        @method  = 'GET'

        @issue_name = 'my issue'
        @input_name = 'vulnerable_input'

        @issues = []
        10.times do |i|
            @issues << Arachni::Issue.new( url: 'http://test.com/' + i.to_s,
                                           name: @issue_name,
                                           internal_modname: @modname,
                                           var: @input_name,
                                           elem: @element,
                                           method: @method )
        end

        issues = Arachni::Issue.new( url: 'http://test.com/hua',
                                     name: 'other issue',
                                     internal_modname: 'modname',
                                     var: 'input_name',
                                     elem: 'cookie',
                                     method: 'POST' )

        framework.checks.register_results( @issues | [issues] )
    end

    def results
        YAML.load <<YAML
---
uniformals:
  Uber kewl check:form:vulnerable_input:
    issue:
      name: my issue
      var: vulnerable_input
      elem: form
      method: GET
    indices:
    - 1
    - 2
    - 3
    - 4
    - 5
    - 6
    - 7
    - 8
    - 9
    - 10
    hashes:
    - c61ff253b87a6f6b662ee1bb4bdcd8e19ea7ecf28216bd1b05dde1084888f258
    - 7a1065b3720f048249a775dc0fe565fd386efdc530028a5cfe6bfb586399ede6
    - 3eddda3522e1a1cbee3ae786d69cd7444610dda337e1f9ae62c9b877304aec1c
    - 9901676b0ee6a3d02dfad85b9ce957947d6f19b37c9d0af8bb425316b38cc22a
    - 0fc968eea1aa581c7b57e43073b5471e1a2b111a907f9a44e45bd6afc2cc5e2a
    - 75e03c80ae71a8d4b390ea2a7ca866447b98681f1e59e66b31c2d23925135e4c
    - d561cc6ff830880a28ec00017056c3c199b10324e7609eae891724e25357c1bb
    - 0e2fe63f234d3ff36ecfdb192e29b10020957c72b114053704a0177c8d0d37ad
    - adac8a4dae0a6fdff9a12be5ea6a2950d3417ea453571159bbe56c4325bc0ee6
    - 7447cf004d2c11726ef55714195573cd5d3af88529898d458afdb30c0cb31460
pages:
  Uber kewl check:form:vulnerable_input:
  - http://test.com/0
  - http://test.com/1
  - http://test.com/2
  - http://test.com/3
  - http://test.com/4
  - http://test.com/5
  - http://test.com/6
  - http://test.com/7
  - http://test.com/8
  - http://test.com/9

YAML
    end

    easy_test
end
