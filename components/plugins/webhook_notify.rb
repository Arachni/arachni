# Send a webhook notification and payload after scan.
#
# @author Sean Handley <sean.handley@gmail.com>
# @version 0.1
class Arachni::Plugins::WebhookNotify < Arachni::Plugin::Base

    def run
        wait_while_framework_running
    end

    def clean_up
        report = framework.report

        print_status 'Sending the notification...'

        uri = URI.parse(options[:url])
        http = Net::HTTP.new(uri.host, uri.port)
        if url =~ /^https/
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless options[:verify_ssl]
        end
        request = Net::HTTP::Post.new(uri.path)
        request.add_field('Content-Type', options[:content_type])
        request.body = interpolate_variables(options[:payload])
        http.request(request)

        print_status 'Done.'
    end

    def interpolate_variables( data )
        report       = framework.report
        scanned_url  = framework.options.url
        issues_found = report.issues.size
        time_taken   = report.delta_time

        data.gsub!( "$SCANNED_URL", scanned_url )
        data.gsub!( "$ISSUES_FOUND$", issues_found )
        data.gsub!( "$TIME_TAKEN", time_taken )
    end

    def self.info
        {
            name:        'Webhook notify',
            description: %q{Sends a webhook payload over HTTP/HTTPS at the end of the scan.

Valid payload variables:

$SCANNED_URL$
$ISSUES_FOUND$
$TIME_TAKEN$
                },
            author:      'Sean Handley <sean.handley@gmail.com>',
            version:     '0.1',
            options:     [
                Options::String.new( :url,
                    required:    true,
                    description: 'Webhook URL (fully qualified including scheme)'
                ),
                Options::String.new( :payload,
                    required:    true,
                    description: 'Either XML or JSON payload. Must be well-formed and valid. You can interpolate variables with $VARIABLE_NAME$'
                ),
                Options::MultipleChoice.new( :content_type,
                    description: 'Content type of payload (XML or JSON).',
                    required:    true,
                    default:     'application/json',
                    choices:     ['application/json', 'application/xml']
                ),
                Options::Bool.new( :verify_ssl,
                    description: 'Verify the SSL certificate? (Disable for self-signed certs)'
                )
            ]

        }
    end

end
