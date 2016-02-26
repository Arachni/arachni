=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Send a webhook notification and payload after scan.
#
# @author Sean Handley <sean.handley@gmail.com>
# @version 0.1
class Arachni::Plugins::WebhookNotify < Arachni::Plugin::Base

    def run
        print_status 'Sending the notification...'

        http.post options[:url],
                  body:    interpolate_variables( options[:payload] ),
                  mode:    :sync,
                  headers: { 'Content-Type' => "application/#{options[:content_type].downcase}" }

        print_status 'Done.'
    end

    def interpolate_variables( data )
        report       = framework.report
        scanned_url  = framework.options.url
        issues_found = report.issues.size
        time_taken   = report.delta_time

        data.gsub!( "$SCANNED_URL$", scanned_url )
        data.gsub!( "$ISSUES_FOUND$", issues_found )
        data.gsub!( "$TIME_TAKEN$", time_taken )
    end

    def self.info
        {
            name:        'Webhook notify',
            description: %q{Sends a webhook payload over HTTP/HTTPS at the end of the scan.

Valid payload variables to use in the payload:

$SCANNED_URL$
$ISSUES_FOUND$
$TIME_TAKEN$
                },
            author:      'Sean Handley <sean.handley@gmail.com>',
            version:     '0.1',
            options:     [
                Options::URL.new( :url,
                    required:    true,
                    description: 'Webhook URL (fully qualified including scheme)'
                ),
                Options::MultipleChoice.new( :content_type,
                    description: 'Content type of payload (XML or JSON).',
                    required:    true,
                    default:     'JSON',
                    choices:     ['JSON', 'XML']
                ),
                Options::String.new( :payload,
                    required:    true,
                    description: 'Either XML or JSON payload. Must be well-formed and valid. You can interpolate variables with $VARIABLE_NAME$'
                )
            ]

        }
    end

end
