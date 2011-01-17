=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Report

#
# Arachni::Report::Base class
#
# An abstract class for the reports.<br/>
# All reports must extend this.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
# @abstract
#
class Base

    # get the output interface
    include Arachni::UI::Output

    # where to report false positives <br/>
    # info about this should be included in all templates
    REPORT_FP = 'http://github.com/Zapotek/arachni/issues'


    #
    # REQUIRED
    #
    def run( )

    end

    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            :name           => 'Report abstract class.',
            :options        => [
                #                    option name    required?       description                         default
                # Arachni::OptBool.new( 'html',    [ false, 'Include the HTML responses in the report?', true ] ),
                # Arachni::OptBool.new( 'headers', [ false, 'Include the headers in the report?', true ] ),
            ],
            :description    => %q{This class should be extended by all reports.},
            :author         => 'zapotek',
            :version        => '0.1',
        }
    end

end

end
end
