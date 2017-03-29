=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Plugins::Metrics < Arachni::Plugin::Base

    def prepare
        @metrics = {
            'general'   => {
                'egress_traffic'  => 0,
                # Approximation, may differ from the real value depending on
                # compression and other factors.
                'ingress_traffic' => 0,
                'uses_http'       => false,
                'uses_https'      => false
            },
            'scan'      => {
                'duration'      => 0,
                'authenticated' => false
            },
            'http'      => {
                'requests'              => 0,
                'request_time_outs'     => 0,
                'request_size_min'      => 0,
                'request_size_max'      => 0,
                'request_size_average'  => 0,
                'responses_per_second'  => 0.0,
                'response_time_min'     => 0,
                'response_time_max'     => 0,
                'response_time_average' => 0,
                'response_size_min'     => 0,
                'response_size_max'     => 0,
                'response_size_average' => 0
            },
            'browser_cluster' => {
                'seconds_per_job' => 0.0,
                'total_job_time'  => 0.0,
                'job_time_outs'   => 0.0,
                'job_count'       => 0
            },
            'resource'  => {
                'binary'             => Arachni::Support::LookUp::HashSet.new,
                'without_parameters' => Arachni::Support::LookUp::HashSet.new,
                'with_parameters'    => Arachni::Support::LookUp::HashSet.new
            },
            'element'   => {
                'links'                    => 0,
                'forms'                    => 0,
                'cookies'                  => 0,
                'jsons'                    => 0,
                'xmls'                     => 0,
                'headers'                  => 0,
                'has_forms_with_nonces'    => false,
                'has_forms_with_passwords' => false,
                'input_names_total'        => 0,
                'input_names_unique'       => Arachni::Support::LookUp::HashSet.new
            },
            'dom'       => {
                'event_listeners' => Arachni::Support::LookUp::HashSet.new,
                'swf_objects'     => Arachni::Support::LookUp::HashSet.new
            },
            'platforms' => Arachni::Platform::Manager::TYPES.keys.
                inject({}) { |h, t| h[t.to_s] = Set.new; h }
        }
    end

    def run
        http_response_time_total = 0

        http.on_complete do |response|
            response.platforms.to_a.each do |platform|
                @metrics['platforms'][Arachni::Platform::Manager.find_type( platform ).to_s] << platform.to_s
            end

            @metrics['general']['egress_traffic']  += response.request.to_s.size
            @metrics['general']['ingress_traffic'] += response.to_s.size

            if @metrics['http']['response_time_min'].is_a?( Integer ) ||
                response.time < @metrics['http']['response_time_min']

                @metrics['http']['response_time_min'] = response.time
            end
            if response.time > @metrics['http']['response_time_max']
                @metrics['http']['response_time_max'] = response.time
            end

            response_size = response.to_s.size
            if @metrics['http']['response_size_min'].is_a?( Integer ) ||
                response_size < @metrics['http']['response_size_min']

                @metrics['http']['response_size_min'] = response_size
            end
            if response_size > @metrics['http']['response_size_max']
                @metrics['http']['response_size_max'] = response_size
            end

            request_size = response.request.to_s.size
            if @metrics['http']['request_size_min'].is_a?( Integer ) ||
                request_size < @metrics['http']['request_size_min']

                @metrics['http']['request_size_min'] = request_size
            end
            if request_size > @metrics['http']['request_size_max']
                @metrics['http']['request_size_max'] = request_size
            end

            # Only track OK codes, otherwise discovery checks will muck with the
            # data.
            if response.code == 200
                if response.request.body.is_a?( Hash ) ||
                    response.request.parameters.any? ||
                    response.request.url.include?( '?' )

                    if response.request.body.is_a? Hash
                        body = response.request.body.keys.sort
                    else
                        body = nil
                    end

                    @metrics['resource']['with_parameters'] <<
                        "#{response.parsed_url.up_to_path}#{response.request.parameters.keys.sort}:#{body}"
                else
                    @metrics['resource']['without_parameters'] << response.url
                end
            end

            @metrics['general']['uses_http']  ||=
                (response.parsed_url.scheme == 'http')
            @metrics['general']['uses_https'] ||=
                (response.parsed_url.scheme == 'https')

            if !response.text?
                @metrics['resource']['binary'] << response.url
            end

            http_response_time_total += response.time
        end

        framework.on_page_audit do |page|
            %w(links forms cookies headers jsons xmls).each do |type|
                page.send( type ).each do |e|
                    next if e.inputs.empty?

                    @metrics['element'][type]                += 1
                    @metrics['element']['input_names_total'] += e.inputs.size

                    e.inputs.keys.each do |name|
                        @metrics['element']['input_names_unique'] << name
                    end

                    if e.is_a? Arachni::Element::Form
                        # Probably not a real form, just a request with inputs
                        # captured by the browsers and fed back to the system.
                        if !e.source
                            @metrics['element'][type] -= 1
                        end

                        @metrics['element']['has_forms_with_nonces']    ||= !!e.has_nonce?
                        @metrics['element']['has_forms_with_passwords'] ||= !!e.requires_password?
                    end
                end
            end

            if (swf = find_swf( page ))
                @metrics['dom']['swf_objects'] << swf
            end

            if Arachni::Options.scope.dom_depth_limit.to_i < page.dom.depth + 1 &&
                browser_cluster && page.has_script?

                with_browser do |browser|
                    browser.load( page ).each_element_with_events do |locator, event_data|
                        event_data.each do |data|
                            @metrics['dom']['event_listeners'] << "#{locator}:#{data}"
                        end
                    end
                end
            end
        end

        wait_while_framework_running

        metrics = process( @metrics )

        statistics = framework.statistics

        metrics['browser_cluster']['job_time_outs'] =
            statistics[:browser_cluster][:time_out_count]

        metrics['browser_cluster']['seconds_per_job'] =
            statistics[:browser_cluster][:seconds_per_job]

        metrics['browser_cluster']['total_job_time'] =
            statistics[:browser_cluster][:total_job_time]

        metrics['browser_cluster']['job_count'] =
            statistics[:browser_cluster][:queued_job_count]

        metrics['http']['requests'] = statistics[:http][:response_count]

        metrics['http']['request_time_outs']    = statistics[:http][:time_out_count]
        metrics['http']['responses_per_second'] = statistics[:http][:total_responses_per_second]

        if metrics['http']['requests'] > 0
            metrics['http']['response_time_average'] =
                http_response_time_total / metrics['http']['requests']

            metrics['http']['response_size_average'] =
                metrics['general']['ingress_traffic'] / metrics['http']['requests']

            metrics['http']['request_size_average'] =
                metrics['general']['egress_traffic'] / metrics['http']['requests']
        end

        metrics['scan']['duration']      = statistics[:runtime]
        metrics['scan']['authenticated'] = !!Arachni::Options.session.check_url

        register_results metrics
    end

    def find_swf( page )
        page.body.scan( /(?:data|src)=['"]?(.*)\.swf['"]?>/ )[0]
    end

    def process( hash )
        h = {}
        hash.each do |k, v|
            case v
                when Hash
                    v = process( v )

                when Set
                    v = v.to_a

                when Arachni::Support::LookUp::HashSet
                    v = v.size

            end

            h[k] = v
        end
        h
    end

    def self.info
        {
            name:        'Metrics',
            description: %q{
Captures metrics about multiple aspects of the scan and the web application.
},
            author:      'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:     '0.1.2'
        }
    end

end
