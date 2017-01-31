=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'pony'

# Uses the Pony gem send a notification (and optionally report) at the end
# of the scan over SMTP.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Plugins::EmailNotify < Arachni::Plugin::Base

    TRIES = 5

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
                user_name:            !options[:username].empty? ? options[:username] : nil,
                password:             !options[:password].empty? ? options[:password] : nil,
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

        sent      = false
        exception = nil
        TRIES.times do |i|
            begin
                Pony.mail( opts )
                sent = true
                break
            rescue => e
                exception = e
                print_bad "Attempt ##{i} failed, retrying..."
            end
        end

        if sent
            print_status 'Done.'
        else
            print_error "Failed after #{TRIES} tries."
            print_exception exception
        end
    end

    def self.info
        {
            name:        'E-mail notify',
            description: %q{Sends a notification (and optionally a report) over SMTP at the end of the scan.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.7',
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
                    default:     'afr',
                    choices:     ['xml', 'html', 'json', 'yaml', 'marshal', 'afr', 'none']
                )
            ]

        }
    end

end
