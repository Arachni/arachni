=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

# Tries to force directory listings.
#
# Can't take credit for this one, it's Michal's (lcamtuf's) method from Skipfish.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.4
class Arachni::Checks::DirectoryListing < Arachni::Check::Base

    # The compared pages must be at least 75% different
    DIFF_THRESHOLD = 0.75

    def self.dirs
        @dirs ||= [ "\\.#{seed}\\", "\\.\\", ".#{seed}/", "./" ]
    end

    def run
        return if page.code != 200
        path = get_path( page.url )

        parsed_path = uri_parse( path ).path
        return if parsed_path == '/' || audited?( parsed_path )

        @harvested = []

        dirs = [ page.url ] | self.class.dirs.map { |dir| path + dir } | [ path ]
        dirs.each_with_index do |url, i|
            http.get( url ) do |res|
                next if !res
                @harvested[i] = res
                check_and_log( path ) if done_harvesting?
            end
        end
    end

    def done_harvesting?
        return false if @harvested.size != 6
        @harvested.each { |res| return false if !res }
        true
    end

    def check_and_log( path )
        audited( path )

        # if we have a 403 Forbidden it means that we successfully
        # built a pah which would force a directory listing *but*
        # the web server kicked our asses...so let's run away like
        # little girls...
        @harvested.each { |res| return if res.code == 403 }

        if !File.basename( @harvested[0].url, '?*' ).empty? &&
            same_page?( @harvested[0], @harvested[5] )
            return
        end

        if same_page?( @harvested[1], @harvested[0] )  ||
            same_page?( @harvested[1], @harvested[2] ) ||
            same_page?( @harvested[3], @harvested[0] ) ||
            same_page?( @harvested[3], @harvested[4] ) ||
            @harvested[5].code != 200 || @harvested[5].body.empty?
            return
        end

        log vector: Element::Server.new( @harvested[5] ), response: @harvested[5]
    end

    def same_page?( res1, res2 )
        res1.code == res2.code && res1.body.diff_ratio( res2.body ) <= DIFF_THRESHOLD
    end

    def self.info
        {
            name:        'Directory listing',
            description: %q{Tries to force directory listings.},
            elements:    [ Element::Server ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.4',
            targets:     %w(Generic),

            issue:       {
                name:        %q{Directory listing},
                description: %q{In most circumstances enabling directory listings is a bad practice
    as it allows an attacker to better grasp the web application's structure.},
                references: {
                    'CWE' => 'http://cwe.mitre.org/data/definitions/548.html'
                },
                tags:        %w(path directory listing index),
                cwe:         548,
                severity:    Severity::LOW,
                remedy_guidance: %q{Restrict access to important directories or files by adopting a need to know requirement for both the document and server root,
                    and turn off features such as Automatic Directory Listings.}
            }
        }
    end

end
