=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'pony'

#
# Uses the Pony gem send a notification (and optionally report) at the end
# of the scan over SMTP.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.2
#
class Arachni::Plugins::EmailNotify < Arachni::Plugin::Base

    def run
        wait_while_framework_running
        @auditstore = framework.auditstore
    end

    def clean_up
        issue_cnt = @auditstore.issues.size
        time      = @auditstore.delta_time
        url       = framework.opts.url

        opts = {
            subject:     "Scan for #{url} finished in #{time}",
            body:        "Found #{issue_cnt} unique issues.",
            to:          options['to'],
            cc:          options['cc'],
            bcc:         options['bcc'],
            from:        options['from'],
            via:         :smtp,
            via_options: {
                address:              options['server_address'],
                port:                 options['server_port'],
                enable_starttls_auto: options['tls'],
                user_name:            options['username'],
                password:             options['password'],
                authentication:       !options['authentication'].empty? ? options['authentication'].to_sym : nil,
                domain:               "localhost.localdomain"
            }
        }

        if options['report'] != 'none'
            report = framework.reports[ options['report'] ]

            rep_opts = {}
            report.info[:options].each do |opt|
                rep_opts[opt.name] = opt.default if opt.default
            end

            rep_opts['outfile'] = 'scan_report.' + options['report']
            report.new( @auditstore, rep_opts ).run

            opts[:attachments] = {
                rep_opts['outfile'] => File.read( rep_opts['outfile'] )
            }

            FileUtils.rm( rep_opts['outfile'] )
        end

        print_status 'Sending the notification...'

        Pony.mail( opts )

        print_status 'Done.'
    end

    def self.info
        {
            name: 'E-mail notify',
            description: %q{Sends a notification (and optionally a report) over SMTP at the end of the scan.},
            author: 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version: '0.1.2',
            options: [
                Options::String.new( 'to', [true, 'E-mail address of the receiver.'] ),
                Options::String.new( 'cc', [false, 'E-mail address to which to send a carbon copy of the notification.'] ),
                Options::String.new( 'bcc', [false, 'E-mail address for a blind carbon copy.'] ),
                Options::String.new( 'from', [true, 'E-mail address of the sender.'] ),
                Options::Address.new( 'server_address', [true, 'Address of the SMTP server to use.'] ),
                Options::Port.new( 'server_port', [true, 'SMTP port.'] ),
                Options::Bool.new( 'tls', [false, 'Use TLS/SSL?.'] ),
                Options::String.new( 'username', [true, 'SMTP username.'] ),
                Options::String.new( 'password', [true, 'SMTP password.'] ),
                Options::String.new( 'authentication', [false, 'Authentication.', 'plain', ['plain', 'login', 'cram_md5', '']] ),
                Options::Enum.new( 'report', [false, 'Report type to send as an attachment.', 'txt', ['txt', 'xml', 'html', 'json', 'yaml', 'marshal' 'none']] )
            ]

        }
    end

end
