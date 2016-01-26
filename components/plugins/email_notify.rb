=begin
    Copyright 2010-2016 Tasos Laskos <tasos.laskos@arachni-scanner.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'pony'

# Uses the Pony gem send a notification (and optionally report) at the end
# of the scan over SMTP.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1.5
class Arachni::Plugins::EmailNotify < Arachni::Plugin::Base

    def run
        wait_while_framework_running
    end

    def clean_up
        report = framework.report

        opts = {
            subject:     "Scan for #{framework.options.url} finished in #{report.delta_time}",
            body:        "Found #{report.issues.size} unique issues.",
            to:          options[:to],
            cc:          options[:cc],
            bcc:         options[:bcc],
            from:        options[:from],
            via:         :smtp,
            via_options: {
                address:              options[:server_address],
                port:                 options[:server_port],
                enable_starttls_auto: options[:tls],
                user_name:            options[:username],
                password:             options[:password],
                authentication:       !options[:authentication].empty? ? options[:authentication].to_sym : nil,
                domain:               options[:domain]
            }
        }

        if options[:report] == 'afr'
            opts[:attachments] = {
                'report.afr' => framework.report.to_afr
            }
        elsif options[:report] != 'none'
            extension = framework.reporters[options[:report]].
                outfile_option.default.split( '.', 2 ).last
            framework.reporters.delete( options[:report] )

            opts[:attachments] = {
                "report.#{extension}" => framework.report_as( options[:report] )
            }
        end

        print_status 'Sending the notification...'

        Pony.mail( opts )

        print_status 'Done.'
    end

    def self.info
        {
            name:        'E-mail notify',
            description: %q{Sends a notification (and optionally a report) over SMTP at the end of the scan.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.6',
            options:     [
                Options::String.new( :to,
                    required:    true,
                    description: 'E-mail address of the receiver.'
                ),
                Options::String.new( :cc,
                    description: 'E-mail address to which to send a carbon copy of the notification.'
                ),
                Options::String.new( :bcc,
                    description: 'E-mail address for a blind carbon copy.'
                ),
                Options::String.new( :from,
                    required:    true,
                    description: 'E-mail address of the sender.'
                ),
                Options::Address.new( :server_address,
                    required:    true,
                    description: 'Address of the SMTP server to use.'
                ),
                Options::Port.new( :server_port,
                    required:    true,
                    description: 'SMTP port.'
                ),
                Options::Bool.new( :tls,
                    description: 'Use TLS/SSL?.'
                ),
                Options::String.new( :username,
                    description: 'SMTP username.'
                ),
                Options::String.new( :password,
                    description: 'SMTP password.'
                ),
                Options::String.new( :domain,
                    description: 'Domain.',
                    default:     'localhost.localdomain'
                ),
                Options::MultipleChoice.new( :authentication,
                    description: 'Authentication.',
                    default:     '',
                    choices:     ['plain', 'login', 'cram_md5', '']
                ),
                Options::MultipleChoice.new( :report,
                    description: 'Report format to send as an attachment.',
                    default:     'txt',
                    choices:     ['txt', 'xml', 'html', 'json', 'yaml', 'marshal', 'afr', 'none']
                )
            ]

        }
    end

end
