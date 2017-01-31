=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'json'

# Converts the Report to a Hash which it then dumps in JSON format into a file.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.1.3
class Arachni::Reporters::JSON < Arachni::Reporter::Base

    def run
        print_line
        print_status "Dumping audit results in #{outfile}."

        File.open( outfile, 'w' ) do |f|
            begin
                f.write ::JSON::pretty_generate( report.to_h )
            rescue Encoding::UndefinedConversionError
                f.write ::JSON::pretty_generate( report.to_h.recode )
            end
        end

        print_status 'Done!'
    end

    def self.info
        {
            name:         'JSON',
            description:  %q{Exports the audit results as a JSON (.json) file.},
            content_type: 'application/json',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:      '0.1.3',
            options:      [ Options.outfile( '.json' ) ]
        }
    end

end
