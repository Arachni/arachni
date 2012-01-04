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
# Goes through all the issues and checks for signs of uniformity using
# the following criteria:
#   * Element type (link, form, cookie, header)
#   * Variable/input name
#   * The module that logged/discovered the issue -- issue type
#
# If the above are all the same for more than 1 page we have a hit.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class Uniformity < Arachni::Plugin::Base

    include Arachni::Module::Utilities

    SEVERITY = Issue::Severity::HIGH

    ELEMENTS = [
        Issue::Element::LINK,
        Issue::Element::FORM,
        Issue::Element::COOKIE,
        Issue::Element::HEADER
    ]

    def prepare
        wait_while_framework_running
    end

    def run
        # will hold the hash IDs of inconclusive issues
        uniformals = {}
        pages      = {}

        @framework.audit_store.deep_clone.issues.each_with_index {
            |issue, idx|

            if issue.severity == SEVERITY && ELEMENTS.include?( issue.elem ) && issue.var

                id = issue.elem + ':' + issue.var + ':' + issue.internal_modname

                uniformals[id] ||= {
                    'issue'  => {
                        'name'   => issue.name,
                        'var'    => issue.var,
                        'elem'   => issue.elem,
                        'method' => issue.method
                    },
                    'indices' => [],
                    'hashes'  => []
                }

                pages[id]      ||= []

                pages[id]      << issue.url
                uniformals[id]['indices'] << idx + 1
                uniformals[id]['hashes']  << issue._hash

            end
        }

        uniformals.reject!{ |k, v| v['hashes'].empty? || v['hashes'].size == 1 }
        pages.reject!{ |k, v| v.size == 1 }

        return if pages.empty?
        register_results(  { 'uniformals' => uniformals, 'pages' => pages } )
    end

    def self.info
        {
            :name           => 'Uniformity (Lack of central sanitization)',
            :description    => %q{Analyzes the scan results and logs issues which persist across different pages.
                This is usually a sign for a lack of a central/single point of input sanitization,
                a bad coding practise.},
            :author         => 'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            :tags           => [ 'meta' ],
            :version        => '0.1.1'
        }
    end

end

end
end
