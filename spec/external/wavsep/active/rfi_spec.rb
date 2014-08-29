require 'spec_helper'

describe 'WAVSEP RFI' do
    include_examples 'wavsep'

    def self.common
        {
            checks:    :rfi,
            vulnerable: [
                'Case01-RFI-UrlClass-FilenameContext-Unrestricted-HttpURL-DefaultFullInput-AnyPathReq-Read.jsp',
                'Case02-RFI-UrlClass-FilenameContext-Unrestricted-HttpURL-DefaultRelativeInput-AnyPathReq-Read.jsp',
                'Case03-RFI-UrlClass-FilenameContext-Unrestricted-HttpURL-DefaultInvalidInput-AnyPathReq-Read.jsp',
                'Case04-RFI-UrlClass-FilenameContext-Unrestricted-HttpURL-DefaultEmptyInput-AnyPathReq-Read.jsp',
                'Case05-RFI-UrlClass-FilenameContext-Unrestricted-HttpURL-DefaultFullInput-NoProtocolReq-Read.jsp',
                'Case06-RFI-UrlClass-FilenameContext-Unrestricted-HttpURL-DefaultInvalidInput-NoProtocolReq-Read.jsp',
                'Case07-RFI-UrlClass-FilenameContext-Unrestricted-HttpURL-DefaultEmptyInput-NoProtocolReq-Read.jsp',
                'Case08-RFI-UrlClass-FilenameContext-HttpInputValidation-HttpURL-DefaultRelativeInput-AnyPathReq-Read.jsp',
                'Case09-RFI-UrlClass-FilenameContext-HttpInputRemoval-HttpURL-DefaultRelativeInput-AnyPathReq-Read.jsp'
            ]
        }
    end

    def self.test_cases( http_method )
        {
            'Erroneous 500 Responses'                  => "RFI/RFI-Detection-Evaluation-#{http_method}-500Error/",
            'Erroneous 404 Responses'                  => "RFI/RFI-Detection-Evaluation-#{http_method}-404Error/",
            'Erroneous 200 Responses'                  => "RFI/RFI-Detection-Evaluation-#{http_method}-200Error/",
            '302 Redirection Responses'                => "RFI/RFI-Detection-Evaluation-#{http_method}-302Redirect/",
            '200 Responses With Differentiation'       => "RFI/RFI-Detection-Evaluation-#{http_method}-200Valid/",
            '200 Responses with Default File on Error' => "RFI/RFI-Detection-Evaluation-#{http_method}-200Identical/"
        }.inject({}){ |h, (k, v)| h.merge( k => { url: v }.merge( common )) }
    end

    easy_test
end
