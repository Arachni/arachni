=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Looks for Js eval use
#
# @author Lionel PRAT <lionel.prat9@gmail.com>
class Arachni::Checks::JsEval < Arachni::Check::Base

    def self.regexp
        @regexp ||= /\s+eval\(.*\);/im
    end

    def run
        match_and_log( self.class.regexp ) { |m| m && !m.empty? }
    end

    def self.info
        description = %q{Use JS eval with var taint is dangerous.}
        {
            name:        'JS eval use',
            description: description,
            elements:    [ Element::Body ],
            author:      'Lionel PRAT <lionel.prat9@gmail.com>',
            version:     '0.0.1',

            issue:       {
                name:        %q{JS eval use},
                cwe:         200,
                description: description,
                severity:    Severity::LOW
            }
        }
    end

end
