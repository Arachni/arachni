require 'spec_helper'

describe 'WAVSEP Unvalidated Redirect' do
    include_examples 'wavsep'

    def self.test_cases( http_method )
        {
            'HTTP redirect'       => {
                url:        "Unvalidated-Redirect/Redirect-Detection-Evaluation-#{http_method}-302Redirect/",
                checks:     'unvalidated_redirect',

                vulnerable: [
                    'Case01-Redirect-RedirectMethod-FilenameContext-Unrestricted-HttpURL-DefaultFullInput-AnyPathReq-Read.jsp',
                    'Case02-Redirect-RedirectMethod-FilenameContext-Unrestricted-HttpURL-DefaultRelativeInput-AnyPathReq-Read.jsp',
                    'Case03-Redirect-RedirectMethod-FilenameContext-Unrestricted-HttpURL-DefaultInvalidInput-AnyPathReq-Read.jsp',
                    'Case04-Redirect-RedirectMethod-FilenameContext-Unrestricted-HttpURL-DefaultEmptyInput-AnyPathReq-Read.jsp',
                    'Case05-Redirect-RedirectMethod-FilenameContext-Unrestricted-HttpURL-DefaultPartialInput-PartialPathReq-Read.jsp',
                    'Case06-Redirect-RedirectMethod-FilenameContext-Unrestricted-HttpURL-DefaultInvalidInput-PartialPathReq-Read.jsp',
                    'Case07-Redirect-RedirectMethod-FilenameContext-Unrestricted-HttpURL-DefaultEmptyInput-PartialPathReq-Read.jsp',
                    'Case08-Redirect-RedirectMethod-FilenameContext-HttpInputValidation-HttpURL-DefaultPartialInput-PartialPathReq-Read.jsp',
                    'Case09-Redirect-RedirectMethod-FilenameContext-HttpInputValidation-HttpURL-DefaultRelativeInput-AnyPathReq-Read.jsp',
                    'Case10-Redirect-RedirectMethod-FilenameContext-HttpInputValidation-HttpURL-DefaultInvalidInput-AnyPathReq-Read.jsp',
                    'Case11-Redirect-RedirectMethod-FilenameContext-HttpInputValidation-HttpURL-DefaultEmptyInput-AnyPathReq-Read.jsp',
                    'Case12-Redirect-RedirectMethod-FilenameContext-HttpInputRemoval-HttpURL-DefaultPartialInput-PartialPathReq-Read.jsp',
                    'Case13-Redirect-RedirectMethod-FilenameContext-HttpInputRemoval-HttpURL-DefaultRelativeInput-AnyPathReq-Read.jsp',
                    'Case14-Redirect-RedirectMethod-FilenameContext-HttpInputRemoval-HttpURL-DefaultInvalidInput-AnyPathReq-Read.jsp',
                    'Case15-Redirect-RedirectMethod-FilenameContext-HttpInputRemoval-HttpURL-DefaultEmptyInput-AnyPathReq-Read.jsp'
                ]
            },

            'JavaScript redirect' => {
                url:        "Unvalidated-Redirect/Redirect-JavaScript-Detection-Evaluation-#{http_method}-200Valid/",
                checks:     'unvalidated_redirect',

                vulnerable: [
                    'Case01-Redirect-RedirectMethod-FilenameContext-Unrestricted-HttpURL-DefaultFullInput-AnyPathReq-Read.jsp',
                    'Case02-Redirect-RedirectMethod-FilenameContext-Unrestricted-HttpURL-DefaultRelativeInput-AnyPathReq-Read.jsp',
                    'Case03-Redirect-RedirectMethod-FilenameContext-Unrestricted-HttpURL-DefaultInvalidInput-AnyPathReq-Read.jsp',
                    'Case04-Redirect-RedirectMethod-FilenameContext-Unrestricted-HttpURL-DefaultEmptyInput-AnyPathReq-Read.jsp',
                    'Case05-Redirect-RedirectMethod-FilenameContext-Unrestricted-HttpURL-DefaultPartialInput-PartialPathReq-Read.jsp',
                    'Case06-Redirect-RedirectMethod-FilenameContext-Unrestricted-HttpURL-DefaultInvalidInput-PartialPathReq-Read.jsp',
                    'Case07-Redirect-RedirectMethod-FilenameContext-Unrestricted-HttpURL-DefaultEmptyInput-PartialPathReq-Read.jsp',
                    'Case08-Redirect-RedirectMethod-FilenameContext-HttpInputValidation-HttpURL-DefaultPartialInput-PartialPathReq-Read.jsp',
                    'Case09-Redirect-RedirectMethod-FilenameContext-HttpInputValidation-HttpURL-DefaultRelativeInput-AnyPathReq-Read.jsp',
                    'Case10-Redirect-RedirectMethod-FilenameContext-HttpInputValidation-HttpURL-DefaultInvalidInput-AnyPathReq-Read.jsp',
                    'Case11-Redirect-RedirectMethod-FilenameContext-HttpInputValidation-HttpURL-DefaultEmptyInput-AnyPathReq-Read.jsp',
                    'Case12-Redirect-RedirectMethod-FilenameContext-HttpInputRemoval-HttpURL-DefaultPartialInput-PartialPathReq-Read.jsp',
                    'Case13-Redirect-RedirectMethod-FilenameContext-HttpInputRemoval-HttpURL-DefaultRelativeInput-AnyPathReq-Read.jsp',
                    'Case14-Redirect-RedirectMethod-FilenameContext-HttpInputRemoval-HttpURL-DefaultInvalidInput-AnyPathReq-Read.jsp',
                    'Case15-Redirect-RedirectMethod-FilenameContext-HttpInputRemoval-HttpURL-DefaultEmptyInput-AnyPathReq-Read.jsp'
                ]
            }
        }
    end

    easy_test
end
