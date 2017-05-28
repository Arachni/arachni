=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Looks element base64 => search serialized object.
#
# @author Lionel PRAT <lionel.prat9@gmail.com>
class Arachni::Checks::Search_base64 < Arachni::Check::Base

    def self.regexp
        #@regexp ||= /(?:[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{4})*(?:[A-Za-z0-9+\/]{2}%3d%3d|[A-Za-z0-9+\/]{3}=|[A-Za-z0-9+\/]{3}%3d)/im
        @regexp ||= /(?:(?:[A-Za-z0-9+\/]|%2F|%2B){4})*(?:(?:[A-Za-z0-9+\/]|%2F|%2B){2}==|(?:[A-Za-z0-9+\/]|%2F|%2B){4})*(?:(?:[A-Za-z0-9+\/]|%2F|%2B){2}%3d%3d|(?:[A-Za-z0-9+\/]|%2F|%2B){3}=|(?:[A-Za-z0-9+\/]|%2F|%2B){3}%3d)/im
    end

    def run
        #body maybe contains base64 but not modify by user, select than modify user
        #match_and_log( self.class.regexp ) { |match| valid_base64?( match ) }
        page.forms.each do |form|
            form.inputs.each do |n, v|
                #next if form.details_for( n )[:type] != :hidden
                next if !(v =~ self.class.regexp)
                list_match = v.scan(self.class.regexp)
                for elem_match in list_match
                    elem_match=elem_match.gsub('%3D',"=")
                    elem_match=elem_match.gsub('%2B',"+")
                    elem_match=elem_match.gsub('%2F',"/")
                    elem_match=elem_match.gsub('%3d',"=")
                    elem_match=elem_match.gsub('%2b',"+")
                    elem_match=elem_match.gsub('%2f',"/")
                    next if !(Base64.encode64(Base64.decode64(elem_match)) === elem_match + "\n")
                    log(
                        proof: "Encode:" + elem_match + " -- Decode:" + Base64.decode64(elem_match).scan(/[[:print:]]/).join,
                        vector: form
                    )
                end
            end
        end
        
        page.response.headers.each do |k, v|
            next if !(v =~ self.class.regexp)
            list_match = v.scan(self.class.regexp)
            for elem_match in list_match
                elem_match=elem_match.gsub('%3D',"=")
                elem_match=elem_match.gsub('%2B',"+")
                elem_match=elem_match.gsub('%2F',"/")
                elem_match=elem_match.gsub('%3d',"=")
                elem_match=elem_match.gsub('%2b',"+")
                elem_match=elem_match.gsub('%2f',"/")
                next if !(Base64.encode64(Base64.decode64(elem_match)) === elem_match + "\n")
                log(
                    vector: Element::Header.new( url: page.url, inputs: { k => v } ),
                    proof:  "Encode:" + elem_match + " -- Decode:" + Base64.decode64(elem_match).scan(/[[:print:]]/).join
                )
            end
        end
    end

    #
    # Checks for a valid base64
    #
    def valid_base64?( elem_match )
        elem_match=elem_match.gsub('%3D',"=")
        elem_match=elem_match.gsub('%2B',"+")
        elem_match=elem_match.gsub('%2F',"/")
        elem_match=elem_match.gsub('%3d',"=")
        elem_match=elem_match.gsub('%2b',"+")
        elem_match=elem_match.gsub('%2f',"/")
        return if !(Base64.encode64(Base64.decode64(elem_match)) === elem_match + "\n")
        "Encode:" + elem_match + " -- Decode:" + Base64.decode64(elem_match)
    end
    
    def self.info
        description = %q{Logs the existence of base64.
                Base64 possible used for serializ object.}
        {
            name:        'Search Base64',
            description: description,
            elements:    [ Element::Header, Element::Form ],
            author:      'Lionel PRAT <lionel.prat9@gmail.com>',
            version:     '0.0.1',

            issue:       {
                name:        %q{Element in Base64},
                cwe:         200,
                description: description,
                severity:    Severity::LOW
            }
        }
    end

end
