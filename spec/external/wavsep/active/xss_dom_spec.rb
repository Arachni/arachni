require 'spec_helper'

describe 'WAVSEP DOM XSS' do
    include_examples 'wavsep'

    def self.methods
        ['GET']
    end

    def self.test_cases( http_method )
        {
            'Reflected DOM Cross Site Scripting' => {
                url:        "DOM-XSS/DXSS-Detection-Evaluation-#{http_method}-Experimental/",
                checks:    'xss*',

                vulnerable: [
                    'Case01-InjectionDirectlyInToDomXssSinkEval.jsp',
                    'Case02-InjectionDirectlyInToDomXssSinkLocation.jsp',
                    'Case03-InjectionInToVariableBeingAssignedToDomXssSinkEval.jsp',
                    'Case04-InjectionInToVariableBeingAssignedToDomXssSinkLocation.jsp'
                ]
            }
        }
    end

    easy_test
end
