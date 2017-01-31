=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Tries to force directory listings.
#
# Can't take credit for this one, it's Michal's (lcamtuf's) method from Skipfish.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Checks::DirectoryListing < Arachni::Check::Base

    # The compared pages must be at least 75% different
    DIFF_THRESHOLD = 0.75

    def self.dirs
        @dirs ||= [ "\\.#{random_seed}\\", "\\.\\", ".#{random_seed}/", "./" ]
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

        # If we have a 403 Forbidden it means that we successfully
        # built a pah which would force a directory listing *but*
        # the web server kicked our asses...so let's run away like
        # little girls...
        @harvested.each { |res| return if !res.ok? || res.code == 403 }

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

        log vector: Element::Server.new( @harvested[5].url ), response: @harvested[5]
    end

    def same_page?( res1, res2 )
        res1.code == res2.code && res1.body.diff_ratio( res2.body ) <= DIFF_THRESHOLD
    end

    def self.info
        {
            name:             'Directory listing',
            description:      %q{Tries to force directory listings.},
            elements:         [ Element::Server ],
            author:           'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:          '0.1.7',
            exempt_platforms: Arachni::Platform::Manager::FRAMEWORKS,

            issue:       {
                name:        %q{Directory listing},
                description: %q{
Web servers permitting directory listing are typically used for sharing files.

Directory listing allows the client to view a simple list of all the files and
folders hosted on the web server. The client is then able to traverse each
directory and download the files.

Cyber-criminals will utilise the presence of directory listing to discover
sensitive files, download protected content, or even just learn how the web
application is structured.

Arachni discovered that the affected page permits directory listing.
},
                references: {
                    'WASC' => 'http://projects.webappsec.org/w/page/13246922/Directory%20Indexing'
                },
                tags:        %w(path directory listing index),
                cwe:         548,
                severity:    Severity::LOW,
                remedy_guidance: %q{
Unless the web server is being utilised to share static and non-sensitive files,
enabling directory listing is considered a poor security practice

This can typically be done with a simple configuration change on the server. The
steps to disable the directory listing will differ depending on the type of server
being used (IIS, Apache, etc.).
If directory listing is required, and permitted, then steps should be taken to
ensure that the risk of such a configuration is reduced.

These can include:

1. Requiring authentication to access affected pages.
2. Adding the affected path to the `robots.txt` file to prevent the directory
   contents being searchable via search engines.
3. Ensuring that sensitive files are not stored within the web or document root.
4. Removing any files that are not required for the application to function.
}
            }
        }
    end

end
