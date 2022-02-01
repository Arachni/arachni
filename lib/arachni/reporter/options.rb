=begin
    Copyright 2010-2022 Ecsypno <http://www.ecsypno.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
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

    extend self
end
end
end
