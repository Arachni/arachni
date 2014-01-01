=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

#
# Tries to force directory listings.
#
# Can't take credit for this one, it's Michal's (lcamtuf's) method from Skipfish.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.4
#
class Arachni::Modules::DirectoryListing < Arachni::Module::Base

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

        if !File.basename( @harvested[0].effective_url, '?*' ).empty? &&
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

        log( { element: Element::SERVER }, @harvested[5] )
    end

    def same_page?( res1, res2 )
        res1.code == res2.code && res1.body.diff_ratio( res2.body ) <= DIFF_THRESHOLD
    end

    def self.info
        {
            name:        'Directory listing',
            description: %q{Tries to force directory listings.},
            elements:    [ Element::SERVER ],
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.4',
            targets:     %w(Generic),
            references: {
                'CWE' => 'http://cwe.mitre.org/data/definitions/548.html'
            },
            issue:       {
                name:        %q{Directory listing},
                description: %q{In most circumstances enabling directory listings is a bad practice
    as it allows an attacker to better grasp the web application's structure.},
                tags:        %w(path directory listing index),
                cwe:         '548',
                severity:    Severity::LOW,
                remedy_guidance: %q{Restrict access to important directories or files by adopting a need to know requirement for both the document and server root,
                    and turn off features such as Automatic Directory Listings.}
            }
        }
    end

end
