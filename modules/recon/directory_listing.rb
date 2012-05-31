=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

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

module Arachni
module Modules

#
# Tries to force directory listings.
#
# Can't take credit for this one, it's Michal's (lcamtuf's) method from Skipfish.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.3
#
class DirectoryListing < Arachni::Module::Base

    DIFF_THRESHOLD = 1000

    def prepare
        foo = File.basename( __FILE__, '.rb' )
        @dirs = [
            "\\.#{foo}\\",
            "\\.\\",
            ".#{foo}/",
            "./"
       ]

       @@__checked ||= Set.new
    end

    def run
        return if page.code != 200
        path = get_path( page.url )

        parsed = uri_parse( path )
        return if !parsed.path || parsed.path.gsub( '/', '' ).empty?

        # no redundant checks pl0x! kthxb.
        return if @@__checked.include?( path )

        @harvested = []

        @dirs = [ @page.url ] | @dirs.map { |dir| path + dir } | [ path ]
        @dirs.each_with_index do |url, i|
            http.get( url ) do |res|
                next if !res
                @harvested[i] = res
                __check( path ) if __done_harvesting?
            end
        end
    end

    def __done_harvesting?
        return false if @harvested.size != 6
        @harvested.each { |res| return false if !res }
        true
    end

    def __check( path )
        @@__checked << path

        # if we have a 403 Forbidden it means that we successfully
        # built a pah which would force a directory listing *but*
        # the web server kicked our asses...so let's run away like
        # little girls...
        @harvested.each { |res| return if res.code == 403 }

        if !File.basename( @harvested[0].effective_url, '?*' ).empty? &&
            __same_page?( @harvested[0], @harvested[5] )
            return
        end


        if !__same_page?( @harvested[1], @harvested[0] ) &&
           !__same_page?( @harvested[1], @harvested[2] )
            __log_results( @harvested[5] )
        end

        if !__same_page?( @harvested[3], @harvested[0] ) &&
           !__same_page?( @harvested[3], @harvested[4] )
            __log_results( @harvested[5] )
        end
    end

    def __same_page?( res1, res2 )
        # back out...
        return false if res1.code != res2.code
        return false if (res1.body.size - res2.body.size).abs > DIFF_THRESHOLD
        true
    end

    def self.info
        {
            :name           => 'Directory listing',
            :description    => %q{Tries to force directory listings.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.3',
            :references     => {},
            :targets        => { 'Generic' => 'all' },
            :issue   => {
                :name        => %q{Directory listing is enabled.},
                :description => %q{In most circumstances enabling directory listings is a bad practise
                    as it allows an attacker to better grasp the web application's structure.},
                :tags        => [ 'path', 'directory', 'listing', 'index' ],
                :cwe         => '548',
                :severity    => Issue::Severity::LOW,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }
        }
    end

    def __log_results( res )
        return if res.code != 200 || res.body.empty?

        log_issue(
            :url          => res.effective_url,
            :method       => res.request.method.to_s.upcase,
            :elem         => Issue::Element::SERVER,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        )

        print_ok( 'Found: ' + res.effective_url )
    end

end
end
end
