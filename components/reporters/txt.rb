=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

#
# Creates a plain text report of the audit.
#
# It redirects stdout to an outfile and runs the default (stdout.rb) report.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
#
# @version 0.2.1
#
class Arachni::Reporters::Text < Arachni::Reporter::Base

    def run
        load Arachni::Options.paths.reporters + 'stdout.rb'

        print_line
        print_status "Dumping audit results in #{outfile}."

        # redirect output streams to the outfile
        stdout  = $stdout.dup
        stderr  = $stderr.dup
        $stderr = $stdout = File.new( outfile, 'w' )

        Reporters::Stdout.new( report, options ).run

        $stdout.close
        $stdout = stdout.dup
        $stderr = stderr.dup

        print_status 'Done!'
    end

    def self.info
        {
            name:        'Text',
            description: %q{Exports the audit results as a text (.txt) file.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.2.1',
            options:     [ Options.outfile( '.txt' ) ]
        }
    end

end
