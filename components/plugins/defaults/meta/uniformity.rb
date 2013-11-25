=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

#
# Goes through all the issues and checks for signs of uniformity using
# the following criteria:
#
#   * Element type (link, form, cookie, header)
#   * Variable/input name
#   * The check that logged/discovered the issue -- issue type
#
# If the above are all the same for more than 1 page we have a hit.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.1.3
#
class Arachni::Plugins::Uniformity < Arachni::Plugin::Base

    def prepare
        wait_while_framework_running
    end

    def run
        uniformals = {}
        pages      = {}

        framework.audit_store.deep_clone.issues.each.with_index do |issue, idx|
            next if !issue.var

            id = "#{issue.internal_modname}:#{issue.elem}:#{issue.var}"
            uniformals[id] ||= {
                'issue'   => {
                    'name'   => issue.name,
                    'var'    => issue.var,
                    'elem'   => issue.elem,
                    'method' => issue.method
                },
                'indices' => [],
                'hashes'  => []
            }

            pages[id] ||= []
            pages[id] << issue.url

            uniformals[id]['indices'] << idx + 1
            uniformals[id]['hashes']  << issue.digest
        end

        uniformals.reject! { |_, v| v['hashes'].size <= 1 }
        pages.reject! { |_, v| v.size == 1 }

        return if pages.empty?
        register_results(  { 'uniformals' => uniformals, 'pages' => pages } )
    end

    def self.info
        {
            name:        'Uniformity (Lack of central sanitization)',
            description: %q{Analyzes the scan results and logs issues which persist across different pages.
                This is usually a sign for a lack of a central/single point of input sanitization,
                a bad coding practise.},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            tags:        %w(meta uniformity),
            version:     '0.1.3'
        }
    end

end
