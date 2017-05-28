=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Search hidden in form => possible leak info
#
# @author Lionel PRAT <lionel.prat9@gmail.com>
class Arachni::Checks::Form_hidden < Arachni::Check::Base

    def run
        #body maybe contains base64 but not modify by user, select than modify user
        #match_and_log( self.class.regexp ) { |match| valid_base64?( match ) }
        page.forms.each do |form|
            form.inputs.each do |n, v|
                next if form.details_for( n )[:type] != :hidden
                
                log(
                    proof: "Form contains type hidden Name:" + n + " => " + v,
                    vector: form
                )
            end
        end
    end
    
    def self.info
        description = %q{Logs the existence of type hidden in forms. Possible leak...}
        {
            name:        'Search hidden in form',
            description: description,
            elements:    [ Element::Form ],
            author:      'Lionel PRAT <lionel.prat9@gmail.com>',
            version:     '0.0.1',

            issue:       {
                name:        %q{Element type hidden in form},
                cwe:         200,
                description: description,
                severity:    Severity::INFORMATIONAL
            }
        }
    end

end
