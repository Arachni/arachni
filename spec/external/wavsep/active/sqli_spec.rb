require 'spec_helper'

describe 'WAVSEP SQL Injection' do
    include_examples 'wavsep'

    def self.test_cases( http_method )
        {
            'Erroneous 500 Responses' => {
                checks:    'sql_injection',
                url:        "SQL-Injection/SInjection-Detection-Evaluation-#{http_method}-500Error/",
                vulnerable: [
                    'Case01-InjectionInLogin-String-LoginBypass-WithErrors.jsp',
                    'Case02-InjectionInSearch-String-UnionExploit-WithErrors.jsp',
                    'Case03-InjectionInCalc-String-BooleanExploit-WithErrors.jsp',
                    'Case04-InjectionInUpdate-String-CommandInjection-WithErrors.jsp',
                    'Case05-InjectionInSearchOrderBy-String-BinaryDeliberateRuntimeError-WithErrors.jsp',
                    'Case06-InjectionInView-Numeric-PermissionBypass-WithErrors.jsp',
                    'Case07-InjectionInSearch-Numeric-UnionExploit-WithErrors.jsp',
                    'Case08-InjectionInCalc-Numeric-BooleanExploit-WithErrors.jsp',
                    'Case09-InjectionInUpdate-Numeric-CommandInjection-WithErrors.jsp',
                    'Case10-InjectionInSearchOrderBy-Numeric-BinaryDeliberateRuntimeError-WithErrors.jsp',
                    'Case11-InjectionInView-Date-PermissionBypass-WithErrors.jsp',
                    'Case12-InjectionInSearch-Date-UnionExploit-WithErrors.jsp',
                    'Case13-InjectionInCalc-Date-BooleanExploit-WithErrors.jsp',
                    'Case14-InjectionInUpdate-Date-CommandInjection-WithErrors.jsp',
                    'Case15-InjectionInSearch-DateWithoutQuotes-UnionExploit-WithErrors.jsp',
                    'Case16-InjectionInView-NumericWithoutQuotes-PermissionBypass-WithErrors.jsp',
                    'Case17-InjectionInSearch-NumericWithoutQuotes-UnionExploit-WithErrors.jsp',
                    'Case18-InjectionInCalc-NumericWithoutQuotes-BooleanExploit-WithErrors.jsp',
                    'Case19-InjectionInUpdate-NumericWithoutQuotes-CommandInjection-WithErrors.jsp'
                ]
            },
            'Erroneous 200 Responses'=> {
                checks: 'sql_injection',
                url:     "SQL-Injection/SInjection-Detection-Evaluation-#{http_method}-200Error/",
                vulnerable: [
                     'Case01-InjectionInLogin-String-LoginBypass-With200Errors.jsp',
                     'Case02-InjectionInSearch-String-UnionExploit-With200Errors.jsp',
                     'Case03-InjectionInCalc-String-BooleanExploit-With200Errors.jsp',
                     'Case04-InjectionInUpdate-String-CommandInjection-With200Errors.jsp',
                     'Case05-InjectionInSearchOrderBy-String-BinaryDeliberateRuntimeError-With200Errors.jsp',
                     'Case06-InjectionInView-Numeric-PermissionBypass-With200Errors.jsp',
                     'Case07-InjectionInSearch-Numeric-UnionExploit-With200Errors.jsp',
                     'Case08-InjectionInCalc-Numeric-BooleanExploit-With200Errors.jsp',
                     'Case09-InjectionInUpdate-Numeric-CommandInjection-With200Errors.jsp',
                     'Case10-InjectionInSearchOrderBy-Numeric-BinaryDeliberateRuntimeError-With200Errors.jsp',
                     'Case11-InjectionInView-Date-PermissionBypass-With200Errors.jsp',
                     'Case12-InjectionInSearch-Date-UnionExploit-With200Errors.jsp',
                     'Case13-InjectionInCalc-Date-BooleanExploit-With200Errors.jsp',
                     'Case14-InjectionInUpdate-Date-CommandInjection-With200Errors.jsp',
                     'Case15-InjectionInSearch-DateWithoutQuotes-UnionExploit-With200Errors.jsp',
                     'Case16-InjectionInView-NumericWithoutQuotes-PermissionBypass-With200Errors.jsp',
                     'Case17-InjectionInSearch-NumericWithoutQuotes-UnionExploit-With200Errors.jsp',
                     'Case18-InjectionInCalc-NumericWithoutQuotes-BooleanExploit-With200Errors.jsp',
                     'Case19-InjectionInUpdate-NumericWithoutQuotes-CommandInjection-With200Errors.jsp'
                 ]
            },
            '200 Responses With Differentiation' => {
                checks:    'sql_injection_*',
                url:        "SQL-Injection/SInjection-Detection-Evaluation-#{http_method}-200Valid/",
                vulnerable: [
                    'Case01-InjectionInLogin-String-LoginBypass-WithDifferent200Responses.jsp',
                    'Case02-InjectionInSearch-String-UnionExploit-WithDifferent200Responses.jsp',
                    'Case03-InjectionInCalc-String-BooleanExploit-WithDifferent200Responses.jsp',
                    'Case04-InjectionInUpdate-String-CommandInjection-WithDifferent200Responses.jsp',
                    'Case05-InjectionInSearchOrderBy-String-BinaryDeliberateRuntimeError-WithDifferent200Responses.jsp',
                    'Case06-InjectionInView-Numeric-PermissionBypass-WithDifferent200Responses.jsp',
                    'Case07-InjectionInSearch-Numeric-UnionExploit-WithDifferent200Responses.jsp',
                    'Case08-InjectionInCalc-Numeric-BooleanExploit-WithDifferent200Responses.jsp',
                    'Case09-InjectionInUpdate-Numeric-CommandInjection-WithDifferent200Responses.jsp',
                    'Case10-InjectionInSearchOrderBy-Numeric-BinaryDeliberateRuntimeError-WithDifferent200Responses.jsp',
                    'Case11-InjectionInView-Date-PermissionBypass-WithDifferent200Responses.jsp',
                    'Case12-InjectionInSearch-Date-UnionExploit-WithDifferent200Responses.jsp',
                    'Case13-InjectionInCalc-Date-BooleanExploit-WithDifferent200Responses.jsp',
                    'Case14-InjectionInUpdate-Date-CommandInjection-WithDifferent200Responses.jsp',
                    'Case15-InjectionInSearch-DateWithoutQuotes-UnionExploit-WithDifferent200Responses.jsp',
                    'Case16-InjectionInView-NumericWithoutQuotes-PermissionBypass-WithDifferent200Responses.jsp',
                    'Case17-InjectionInSearch-NumericWithoutQuotes-UnionExploit-WithDifferent200Responses.jsp',
                    'Case18-InjectionInCalc-NumericWithoutQuotes-BooleanExploit-WithDifferent200Responses.jsp',
                    'Case19-InjectionInUpdate-NumericWithoutQuotes-CommandInjection-WithDifferent200Responses.jsp'
                ]
            },
            'Identical 200 Responses' => {
                checks: 'sql_injection_timing',
                url:     "SQL-Injection/SInjection-Detection-Evaluation-#{http_method}-200Identical/",
                vulnerable: [
                     'Case01-InjectionInView-Numeric-Blind-200ValidResponseWithDefaultOnException.jsp',
                     'Case02-InjectionInView-String-Blind-200ValidResponseWithDefaultOnException.jsp',
                     'Case03-InjectionInView-Date-Blind-200ValidResponseWithDefaultOnException.jsp',
                     'Case04-InjectionInUpdate-Numeric-TimeDelayExploit-200Identical.jsp',
                     'Case05-InjectionInUpdate-String-TimeDelayExploit-200Identical.jsp',
                     'Case06-InjectionInUpdate-Date-TimeDelayExploit-200Identical.jsp',
                     'Case07-InjectionInUpdate-NumericWithoutQuotes-TimeDelayExploit-200Identical.jsp',
                     'Case08-InjectionInUpdate-DateWithoutQuotes-TimeDelayExploit-200Identical.jsp'
                 ]
            }
        }
    end

    easy_test do
        Arachni::Data.issues.each do |issue|
            # Timing attack issues can be marked as untrusted sometimes to
            # indicate the possibility of a false positive, make sure we've only
            # got trusted issues.
            expect(issue).to be_trusted
        end
    end
end
