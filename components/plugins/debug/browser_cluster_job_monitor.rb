=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Arachni::Plugins::BrowserClusterJobMonitor < Arachni::Plugin::Base

    def run
        while framework.running?

            s = ''
            browser_cluster.workers.each.with_index do |worker, i|
                s << "[#{i+1}] #{worker.job || '-'}\n"
                s << "#{'-'  * 100}\n"

                worker.proxy.active_connections.each do |connection|
                    next if !connection

                    if connection.request
                        s << "* #{connection.request.url}\n"
                    else
                        s << "* Still reading request data.\n"
                    end
                end

                s << "\n"
            end

            IO.write( options[:logfile], s )

            sleep 1
        end
    end

    def self.info
        {
            name:        'BrowserClusterJobMonitor',
            description: %q{

Monitor with:

    watch -n1 cat /tmp/browser_cluster_job_monitor.log
                         },
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1',
            options:     [
                Options::String.new( :logfile,
                    description: 'Executable to be called prior to the scan.',
                    default: '/tmp/browser_cluster_job_monitor.log'
                )
            ]
        }
    end

end
