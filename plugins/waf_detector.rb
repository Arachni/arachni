=begin
    Copyright 2010-2013 Tasos Laskos <tasos.laskos@gmail.com>

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
# Web Application Firewall detection plugin.
#
# This is a 4 stage process:
#   1. Grab the original page as is
#   2. Send a lot of innocent strings in non-existent inputs so as to profile normal behavior
#   3. Send a lot of suspicious strings in non-existent inputs and check if behavior changes
#   4. Make heads or tails of the gathered responses
#
# Steps 1 to 3 will be repeated _precision_ times and the responses will be averaged using rDiff analysis.
#
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Plugins::WAFDetector < Arachni::Plugin::Base

    MSG_INCONCLUSIVE = %q{Could not establish a baseline behavior for the website. Due to that fact analysis has been aborted.}
    MSG_FOUND        = %q{Request parameters are being filtered, this is usually a sign of a WAF.}
    MSG_NOT_FOUND    = %q{Could not detect any sign of filtering, a WAF doesn't seem to be present.}

    def prepare
        framework.pause

        @precision = options['precision']

        bad = [
            '../../../../',
            '<script>foo</script>',
            '\'--;`',
        ]

        names = []
        bad.size.times do |i|
            names << i.to_s + '_' + Digest::SHA2.hexdigest( rand( i * 1000 ).to_s )
        end

        @safe   = { }
        @unsafe = { }
        names.each.with_index do |name, i|
            @safe[name]   = 'value_' + name
            @unsafe[name] = i.to_s + '_' + bad.join( '_' )
        end

        @url = framework.opts.url

        @responses = {
            original: nil,
            vanilla:  nil,
            spicy:    nil
        }
    end

    def run
        print_status "Starting detection with a precision of #{@precision}."

        print_status "Stage #1: Requesting original page."
        queue_original

        print_status "Stage #2: Requesting with vanilla inputs."
        queue_vanilla

        print_status "Stage #3: Requesting with spicy inputs."
        queue_spicy

        print_status "Stage #4: Analyzing gathered responses."

        http.after_run {
            if @responses[:original] == @responses[:vanilla]
                if @responses[:vanilla] == @responses[:spicy]
                    not_found
                else
                    found
                end
            else
                inconclusive
            end
        }

        http_run
    end

    def clean_up
        framework.resume
    end

    def found
        print_ok MSG_FOUND
        register_results( code: 1, msg: MSG_FOUND )
    end

    def not_found
        print_ok MSG_NOT_FOUND
        register_results( code: 0, msg: MSG_NOT_FOUND )
    end

    def inconclusive
        print_ok MSG_INCONCLUSIVE
        register_results( code: -1, msg: MSG_INCONCLUSIVE )
    end

    def queue_original
        @precision.times {
            http.get( @url.to_s ) do |res|
                @responses[:original] ||= res.body
                @responses[:original] = @responses[:original].rdiff( res.body )
            end
        }
    end

    def queue_vanilla
        @precision.times {
            http.get( @url.to_s, parameters: @safe ) do |res|
                @responses[:vanilla] ||= res.body
                @responses[:vanilla] = @responses[:vanilla].rdiff( res.body )
            end
        }
    end

    def queue_spicy
        @precision.times {
            http.get( @url.to_s, parameters: @unsafe ) do |res|
                @responses[:spicy] ||= res.body
                @responses[:spicy] = @responses[:spicy].rdiff( res.body )
            end
        }
    end

    def self.info
        {
            name:        'WAF Detector',
            description: %q{Performs basic profiling on the web application
                in order to assess the existence of a Web Application Firewall.

                This is a 4 stage process:
                   1. Grab the original page as is
                   2. Send a lot of innocent (vanilla) strings in non-existent inputs so as to profile normal behavior
                   3. Send a lot of suspicious (spicy) strings in non-existent inputs and check if behavior changes
                   4. Make heads or tails of the gathered responses

                 Steps 1 to 3 will be repeated _precision_ times (default: 5) and the responses will be averaged using rDiff analysis.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.2',
            options:     [
                Options::Int.new( 'precision', [false, 'Stage precision (how many times to perform each detection stage).', 5] )
            ]
        }
    end

end
