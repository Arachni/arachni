=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# Send a webhook notification and payload after scan.
#
# @author Sean Handley <sean.handley@gmail.com>
# @author Tasos Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Arachni::Plugins::WebhookNotify < Arachni::Plugin::Base

    def run
        wait_while_framework_running

        print_status 'Sending the notification...'

        response = http.request( options[:url].to_s,
            method:  :post,
            body:    interpolate_variables( options[:payload] ),
            mode:    :sync,
            headers: {
                'Content-Type' => "application/#{options[:content_type]}"
            }
        )

        register_results(
            'success'  => response.ok?,
            'status'   => response.return_code.to_s,
            'message'  => response.return_message,
            'response' => response.to_s
        )

        print_status "Done with HTTP code #{response.code}: " <<
                     "[#{response.return_code}] #{response.return_message}"
    end

    def interpolate_variables( data )
        report = framework.report

        data = data.gsub( '$URL$', framework.options.url )

        data.gsub!( '$SEED$', random_seed )
        data.gsub!( '$ISSUE_COUNT$', report.issues.size.to_s )

        max_severity = ''
        if (max_severity_issue = report.issues.sort.first)
            max_severity = max_severity_issue.severity.to_s
        end
        data.gsub!( '$MAX_SEVERITY$', max_severity )

        data.gsub!( '$DURATION$', report.delta_time )
        data
    end

    def self.info
        {
            name:        'Webhook notify',
            description: %q{
Sends a webhook payload over HTTP/HTTPS at the end of the scan.

Valid payload variables to use in the payload:

* $SEED$ -- Unique seed used for the scan.
* $URL$  -- Targeted URL.
* $MAX_SEVERITY$ -- Maximum severity of the identified issues.
* $ISSUE_COUNT$ -- Amount of identified issues.
* $DURATION$ -- Scan duration.
},
            author:      [
                'Sean Handley <sean.handley@gmail.com>',
                'Tasos Laskos <tasos.laskos@arachni-scanner.com>'
            ],
            version:     '0.1',
            options:     [
                Options::URL.new( :url,
                    required:    true,
                    description: 'Webhook URL (fully qualified including scheme)'
                ),
                Options::MultipleChoice.new( :content_type,
                    description: 'Content type of payload (XML or JSON).',
                    required:    true,
                    default:     'json',
                    choices:     %w(json xml)
                ),
                Options::String.new( :payload,
                    required:    true,
                    description: 'Either XML or JSON payload. Must be well-formed ' <<
                                 'and valid. You can interpolate variables with $VARIABLE_NAME$'
                )
            ]

        }
    end

end
