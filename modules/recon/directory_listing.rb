=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules

#
# Tries to force directory listings.
#
# Can't take credit for this one, it's Michal's (lcamtuf's) method from Skipfish.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class DirectoryListing < Arachni::Module::Base

    include Arachni::Module::Utilities

    DIFF_THRESHOLD = 1000

    def initialize( page )
        super( page )
    end

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

    def run( )

        path = get_path( @page.url )

        return if !URI( path ).path || URI( path ).path.gsub( '/', '' ).empty?

        # no redundant checks pl0x! kthxb.
        return if @@__checked.include?( path )

        @harvested = []

        @dirs = [ @page.url ] | @dirs.map { |dir| path + dir } | [ path ]
        @dirs.each_with_index {
            |url, i|

            @http.get( url ).on_complete {
                |res|

                if res
                    @harvested[i] = res
                    __check( path ) if __done_harvesting?
                end
            }

        }
    end

    def __done_harvesting?

        return false if @harvested.size != 6
        @harvested.each {
            |res|
            return false if !res
        }

        return true
    end

    def __check( path )

        @@__checked << path

        # if we have a 403 Forbidden it means that we succesfully
        # built a pah which would force a directory listing *but*
        # the web server kicked our asses...so let's run away like
        # little girls...
        @harvested.each {
            |res|
            return if res.code == 403
        }

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

        return true
    end

    def self.info
        {
            :name           => 'Directory listing',
            :description    => %q{Tries to force directory listings.},
            :elements       => [ ],
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
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

        issue = Issue.new( {
            :var          => 'n/a',
            :url          => res.effective_url,
            :injected     => 'n/a',
            :method       => res.request.method.to_s.upcase,
            :id           => 'n/a',
            :regexp       => 'n/a',
            :regexp_match => 'n/a',
            :elem         => Issue::Element::SERVER,
            :response     => res.body,
            :verification => 'true',
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        }.merge( self.class.info ) )

        # register our results with the system
        register_results( [issue] )

        print_ok( 'Found: ' + res.effective_url )
    end

end
end
end
