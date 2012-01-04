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
# Gathers all issues that require manual verification into an array.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class ManualVerification < Arachni::Plugin::Base

    def prepare
        wait_while_framework_running
    end

    def run
        # will hold the hash IDs of inconclusive issues
        inconclusive = []
        @framework.audit_store.issues.each.with_index {
            |issue, idx|
            next if !issue.verification

            inconclusive << {
                'hash'   => issue._hash,
                'index'  => idx + 1,
                'url'    => issue.url,
                'name'   => issue.name,
                'var'    => issue.var,
                'elem'   => issue.elem,
                'method' => issue.method
            }
        }

        register_results( inconclusive ) if !inconclusive.empty?
    end

    def self.info
        {
            :name           => 'Issues requiring manual verification',
            :description    => %q{Goes through the list of logged issues and cherry picks the ones that require manual verification.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :version        => '0.1.1',
            :tags           => [ 'anomaly' , 'verification', 'meta' ]
        }
    end

end

end
end
