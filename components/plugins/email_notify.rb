=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'pony'

# Uses the Pony gem send a notification (and optionally report) at the end
# of the scan over SMTP.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
# @version 0.1.3
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
                domain:               'localhost.localdomain'
            }
        }

        if options[:report] != 'none'
            opts[:attachments] = {
                "report.#{options[:report]}" => framework.report_as( options[:report] )
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
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:     '0.1.3',
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
                    required:    true,
                    description: 'SMTP username.'
                ),
                Options::String.new( :password,
                    required:    true,
                    description: 'SMTP password.'
                ),
                Options::MultipleChoice.new( :authentication,
                    description:  'Authentication.',
                    default:      'plain',
                    choices: ['plain', 'login', 'cram_md5', '']
                ),
                Options::MultipleChoice.new( :report,
                    description:  'Report type to send as an attachment.',
                    default:      'txt',
                    choices: ['txt', 'xml', 'html', 'json', 'yaml', 'marshal' 'none']
                )
            ]

        }
    end

end
