=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@arachni-scanner.com>
    Please see the LICENSE file at the root directory of the project.
=end

module Arachni
module Reporter

# Provides some common options for the reports.
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
module Options
    include Component::Options

    # Returns a string option named `outfile`.
    #
    # Default value is:
    #   year-month-day hour.minute.second +timezone.extension
    #
    # @param    [String]    extension     Extension for the outfile.
    # @param    [String]    description   Description of the option.
    #
    # @return   [Arachni::OptString]
    def outfile( extension = '', description = 'Where to save the report.' )
        Options::String.new( :outfile,
                             description: description,
                             default:     Time.now.to_s.gsub( ':', '_' ) + extension
        )
    end

    def skip_responses
        Options::Bool.new( :skip_responses,
                           description: "Don't include the bodies of the HTTP " +
                                            'responses of the issues in the report' +
                                            ' -- will lead to a greatly decreased report file-size.',
                           default:     false
        )
    end

    extend self
end
end
end
