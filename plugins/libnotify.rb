=begin
                  Arachni
  Copyright (c) 2010-2012 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Plugins

#
# Uses the libnotify library to send notifications for each discovered issue
# and a summary at the end on the scan.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class LibNotify < Arachni::Plugin::Base

    def prepare
        return if !@options['for_every_issue']

        Arachni::Module::Manager.on_register_results {
            |issues|
            issues.each {
                |issue|
                notify(
                    :summary   => "Found #{issue.name}",
                    :body      => "In #{issue.elem} variable" +
                        " '#{issue.var}' (Severity: #{issue.severity})\n" +
                        "At #{issue.url}"
                )
            }
        }
    end

    def run
        wait_while_framework_running
    end

    def clean_up
        issue_cnt = @framework.audit_store.issues.size
        time      = @framework.audit_store.delta_time
        url       = @framework.opts.url

        notify(
            :summary   => "Scan finished in #{time}",
            :body      => "Found #{issue_cnt} unique issues for #{url}."
        )
    end

    def notify( opts )
        Libnotify.show({
            :icon_path => @framework.opts.dir['gfx'] + "spider.png",
            :timeout   => 2.5,
            :append    => true
        }.merge( opts ))
    end

    def self.gems
        [ 'libnotify' ]
    end

    def self.info
        {
            :name           => 'libnotify',
            :description    => %q{Uses the libnotify library to send notifications for each discovered issue
                and a summary at the end of the scan.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1',
            :options        => [
                Arachni::OptBool.new( 'for_every_issue', [ false, 'Show every issue.', true ] ),
            ]

        }
    end

end

end
end
