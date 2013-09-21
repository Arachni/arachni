=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# localstart.asp recon module.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1
class Arachni::Modules::LocalstartASP < Arachni::Module::Base

    def run
        return if page.platforms.os.any? && !page.platforms.os.include?( :windows )

        path = get_path( page.url )
        return if audited?( path )
        audited path

        http.get( "#{path}/#{seed}" ) do |response|
            # If it needs auth by default then don't bother checking because
            # we'll get an FP.
            return if response.code == 401

            url = "#{path}/localstart.asp"

            print_status "Checking: #{url}"
            http.get( url, &method( :check_and_log ) )
        end
    end

    def check_and_log( response )
        return if response.code != 401

        log( { element: Element::SERVER }, response )
    end

    def self.info
        {
            name:        'localstart.asp',
            description: %q{Checks for localstart.asp.},
            elements:    [ Element::SERVER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1',
            targets:     %w(Generic),
            issue:       {
                name:            %q{Exposed localstart.asp page},
                description:     %q{The default management ISS page localstart.asp
                    is still on the server.},
                tags:            %w(asp iis server),
                severity:        Severity::LOW
            }
        }
    end

end
