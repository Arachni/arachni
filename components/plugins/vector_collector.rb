=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
# @version 0.1
class Arachni::Plugins::VectorCollector < Arachni::Plugin::Base

    def prepare
        @vectors = {}
    end

    def suspend
        @vectors
    end

    def restore( vectors )
        @vectors = vectors
    end

    def run
        framework.on_effective_page_audit do |page|
            current_vectors = @vectors[page.dom.url] ||= {}

            page.elements_within_scope.each do |element|
                next if element.inputs.empty? ||
                    current_vectors.include?( element.coverage_hash )

                h = element.to_hash

                # :inputs will be identical to :default_inputs since none of
                # the elements will be mutations.
                h.delete :default_inputs

                h = h.my_stringify_keys(false)
                h['method'] = h['method'].to_s if h['method']

                current_vectors[element.coverage_hash] = h.my_stringify_keys(false)
            end

            @vectors.delete( page.dom.url ) if @vectors[page.dom.url].empty?
        end

        wait_while_framework_running
    end

    def clean_up
        @vectors.each do |url, elements|
            @vectors[url] = elements.values
        end

        register_results( @vectors )
    end

    def self.info
        {
            name:        'Vector collector',
            description: %q{
Analyzes each page and collects information about input vectors.

**WARNING**: It will log thousands of results leading to a huge report, highly
increased memory consumption and CPU usage.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1'
        }
    end

end
