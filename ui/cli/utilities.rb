=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

module Arachni

require_relative 'output'
require Options.paths.mixins + 'terminal'

module UI::CLI

module Utilities
    include Arachni::Utilities

    include Support::Mixins::Terminal

    def print_issues( issues, unmute = false, &interceptor )
        issues = issues.sort_by { |i| [i.severity, i.name]}.reverse

        interceptor ||= proc { |s| s }

        print_line( interceptor.call, unmute )
        print_info( interceptor.call( "#{issues.size} issues have been detected." ), unmute )

        print_line( interceptor.call, unmute )

        issue_cnt = issues.size
        issues.each.with_index do |issue, i|
            meth  = input = ''

            if issue.active?
                input = " input `#{issue.affected_input_name}`"
                meth  = " using #{issue.vector.method.to_s.upcase}"
            elsif issue.vector.respond_to?( :inputs )
                input = " with inputs `#{issue.vector.inputs.keys.join(', ')}`"
            end

            cnt = "#{i + 1} |".rjust( issue_cnt.to_s.size + 2 )

            print_ok( interceptor.call(  "#{cnt} #{issue.name} at #{issue.vector.action} in" +
                                  " #{issue.vector.type}#{input}#{meth}." ),
                      unmute
            )
        end

        print_line( interceptor.call, unmute )
    end

    # Outputs all available checks and their info.
    def list_platforms( platform_info )
        print_line
        print_line
        print_info 'Available platforms:'
        print_line

        platform_info.each do |type, platforms|
            print_status "#{type}"

            platforms.each do |shortname, fullname|
                print_info "#{shortname}:\t\t#{fullname}"
            end

            print_line
        end

    end

    # Outputs all available checks and their info.
    def list_checks( checks )
        print_line
        print_line
        print_info 'Available checks:'
        print_line

        checks.each do |info|
            print_status "#{info[:shortname]}:"
            print_line '--------------------'

            print_line "Name:\t\t#{info[:name]}"
            print_line "Description:\t\n#{info[:description].strip}\n\n"

            if info[:issue] && (severity = info[:issue][:severity])
                print_line "Severity:\t#{severity.to_s.capitalize}"
            end

            if info[:elements] && info[:elements].size > 0
                print_line "Elements:\t#{info[:elements].map(&:type).join( ', ' )}"
            end

            print_line "Author:\t\t#{info[:author].join( ', ' )}"
            print_line "Version:\t#{info[:version]}"

            if info[:references]
                print_line 'References:'
                info[:references].keys.each do |key|
                    print_info "#{key}\t\t#{info[:references][key]}"
                end
            end

            if info[:targets]
                print_line 'Targets:'

                if info[:targets].is_a?( Hash )
                    info[:targets].keys.each do |key|
                        print_info "#{key}\t\t#{info[:targets][key]}"
                    end
                else
                    info[:targets].each { |target| print_info( target ) }
                end
            end

            print_line "Path:\t#{info[:path]}"

            print_line
        end

    end

    # Outputs all available reports and their info.
    def list_reporters( reports )
        print_line
        print_line
        print_info 'Available reports:'
        print_line

        reports.each do |info|
            print_status "#{info[:shortname]}:"
            print_line '--------------------'

            print_line "Name:\t\t#{info[:name]}"
            print_line "Description:\t\n#{info[:description].strip}\n\n"

            if info[:options] && !info[:options].empty?
                print_line( "Options:\t" )

                info[:options].each do |option|
                    option = option.is_a?( Hash ) ? option : option.to_h

                    print_info "\t#{option[:name]} - #{option[:description]}"
                    print_info "\tType:        #{option[:type]}"
                    print_info "\tDefault:     #{option[:default]}"
                    print_info "\tRequired?:   #{option[:required]}"

                    print_line
                end
            end

            print_line "Author:\t\t#{info[:author].join( ", " )}"
            print_line "Version:\t#{info[:version] }"
            print_line "Path:\t#{info[:path]}"

            print_line
        end
    end

    # Outputs all available reports and their info.
    def list_plugins( plugins )
        print_line
        print_line
        print_info 'Available plugins:'
        print_line

        plugins.each do |info|
            print_status "#{info[:shortname]}:"
            print_line '--------------------'

            print_line "Name:\t\t#{info[:name]}"
            print_line "Description:\t\n#{info[:description].strip}\n\n"

            if info[:options] && !info[:options].empty?
                print_line "Options:\t"

                info[:options].each do |option|
                    option = option.is_a?( Hash ) ? option : option.to_h

                    print_info "\t#{option[:name]} - #{option[:description]}"
                    print_info "\tType:        #{option[:type]}"
                    if option[:choices]
                        print_info "\tChoices:     #{option[:choices].join(', ')}"
                    end
                    print_info "\tDefault:     #{option[:default]}"
                    print_info "\tRequired?:   #{option[:required]}"

                    print_line
                end
            end

            print_line "Author:\t\t#{info[:author].join( ', ' )}"
            print_line "Version:\t#{info[:version]}"
            print_line "Path:\t#{info[:path]}"

            print_line
        end
    end

    # Loads an Arachni Framework Profile file and merges it with the user
    # supplied options.
    #
    # @param    [String]    profile
    def load_profile( profile )
        exception_jail do
            Arachni::Options.load( profile )
        end
    end

    # Saves options to an Arachni Framework Profile file.
    #
    # @param    [String]    filename
    def save_profile( filename )
        if (filename = Arachni::Options.save( filename ))
            print_status "Saved profile in '#{filename}'."
            print_line
        else
            banner
            print_error 'Could not save profile.'
            exit 0
        end
    end

    # Outputs Arachni banner.
    # Displays version number, author details etc.
    #
    # @see VERSION
    def print_banner
        puts BANNER
        puts
        puts
    end

end
end
end
