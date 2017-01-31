=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

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
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1.3
class Arachni::Plugins::WAFDetector < Arachni::Plugin::Base

    STATUSES = {
        inconclusive: %q{Could not establish a baseline behavior for the website.
            Due to that fact analysis has been aborted.},
        found:        %q{Request parameters are being filtered, this is usually a sign of a WAF.},
        not_found:    %q{Could not detect any sign of filtering, a WAF doesn't seem to be present.}
    }

    def prepare
        @precision = options[:precision]

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

        @url = framework.options.url

        @responses = {
            original: nil,
            vanilla:  nil,
            spicy:    nil
        }

        framework_pause
    end

    def run
        print_status "Starting detection with a precision of #{@precision}."

        print_status 'Stage #1: Requesting original page.'
        queue_original

        print_status 'Stage #2: Requesting with vanilla inputs.'
        queue_vanilla

        print_status 'Stage #3: Requesting with spicy inputs.'
        queue_spicy

        print_status 'Stage #4: Analyzing gathered responses.'

        http.after_run do
            if @responses[:original] == @responses[:vanilla]
                if @responses[:vanilla] == @responses[:spicy]
                    not_found
                else
                    found
                end
            else
                inconclusive
            end
        end

        http.run
    end

    def clean_up
        framework_resume
    end

    def found
        log :found
    end

    def not_found
        log :not_found
    end

    def inconclusive
        log :inconclusive
    end

    def log( status )
        print_ok STATUSES[status]
        register_results( 'status' => status.to_s, 'message' => STATUSES[status] )
    end

    def queue_original
        @precision.times do
            http.get( @url.to_s ) do |res|
                @responses[:original] ||= res.body
                @responses[:original] = @responses[:original].rdiff( res.body )
            end
        end
    end

    def queue_vanilla
        @precision.times do
            http.get( @url.to_s, parameters: @safe ) do |res|
                @responses[:vanilla] ||= res.body
                @responses[:vanilla] = @responses[:vanilla].rdiff( res.body )
            end
        end
    end

    def queue_spicy
        @precision.times do
            http.get( @url.to_s, parameters: @unsafe ) do |res|
                @responses[:spicy] ||= res.body
                @responses[:spicy] = @responses[:spicy].rdiff( res.body )
            end
        end
    end

    def self.info
        {
            name:        'WAF Detector',
            description: %q{
Performs basic profiling on the web application in order to assess the existence
of a Web Application Firewall.

This is a 4 stage process:

1. Grab the original page as is.
2. Send a lot of innocent (vanilla) strings in non-existent inputs so as to
    profile normal behavior.
3. Send a lot of suspicious (spicy) strings in non-existent inputs and check if
    behavior changes.
4. Make heads or tails of the gathered responses.

Steps 1 to 3 will be repeated _precision_ times (default: 5) and the responses
will be averaged using rDiff analysis.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.3',
            options:     [
                Options::Int.new( :precision,
                    description: 'Stage precision (how many times to perform each detection stage).',
                    default:     5
                )
            ]
        }
    end

end
