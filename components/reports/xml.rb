=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'base64'

# Creates an XML report of the audit.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
# @version 0.2.5
class Arachni::Reports::XML < Arachni::Report::Base
    load Arachni::Options.dir['reports'] + '/xml/buffer.rb'

    include Buffer

    def run
        print_line
        print_status 'Creating XML report...'

        append "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
        start_tag 'arachni_report'

        simple_tag( 'title', 'Web Application Security Report - Arachni Framework' )
        simple_tag( 'generated_on', Time.now )
        simple_tag( 'report_false_positives', REPORT_FP )

        start_tag 'system'
        simple_tag( 'version', auditstore.version )
        simple_tag( 'revision', auditstore.revision )
        simple_tag( 'start_datetime', auditstore.start_datetime )
        simple_tag( 'finish_datetime', auditstore.finish_datetime )
        simple_tag( 'delta_time', auditstore.delta_time )

        simple_tag( 'url', auditstore.options['url'] )
        simple_tag( 'user_agent', auditstore.options['user_agent'] )

        start_tag 'audited_elements'
        simple_tag( 'element', 'links' ) if auditstore.options['audit_links']
        simple_tag( 'element', 'forms' ) if auditstore.options['audit_forms']
        simple_tag( 'element', 'cookies' ) if auditstore.options['audit_cookies']
        simple_tag( 'element', 'headers' ) if auditstore.options['audit_headers']
        end_tag 'audited_elements'

        start_tag 'checks'
        auditstore.options['mods'].each { |mod| add_mod( mod ) }
        end_tag 'checks'

        start_tag 'filters'

        %w(exclude include).each do |type|
            if auditstore.options[type]
                start_tag type
                auditstore.options[type].each { |ex| simple_tag( 'regexp', ex ) }
                end_tag type
            end
        end

        if auditstore.options['redundant']
            start_tag 'redundant'
            auditstore.options['redundant'].each do |regexp, counter|
                simple_tag( 'filter', "#{regexp}:#{counter}" )
            end
            end_tag 'redundant'
        end
        end_tag 'filters'

        start_tag 'cookies'
        if auditstore.options['cookies']
            auditstore.options['cookies'].each { |name, value| add_cookie( name, value ) }
        end
        end_tag 'cookies'

        end_tag 'system'

        start_tag 'issues'
        auditstore.issues.each do |issue|
            start_tag 'issue'

            issue.each_pair do |k, v|
                next if !v.is_a?( String )
                simple_tag( k, v )
            end

            add_tags [issue.tags].flatten.compact

            start_tag 'references'
            issue.references.each { |name, url| add_reference( name, url ) }
            end_tag 'references'

            add_variations issue

            end_tag 'issue'
        end

        end_tag 'issues'

        start_tag 'plugins'
        # get XML formatted plugin data and append them to the XML buffer
        # along with some generic info
        format_plugin_results.each do |plugin, results|
            start_tag plugin
            simple_tag( 'name', auditstore.plugins[plugin][:name] )
            simple_tag( 'description', auditstore.plugins[plugin][:description] )

            start_tag 'results'
            append( results )
            end_tag 'results'

            end_tag plugin
        end
        end_tag 'plugins'

        end_tag 'arachni_report'

        File.open( outfile, 'w' ) { |f| f.write( buffer ) }
        print_status "Saved in '#{outfile}'."
    end

    def self.info
        {
            name:         'XML',
            description:  %q{Exports the audit results as an XML (.xml) file.},
            content_type: 'text/xml',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>',
            version:      '0.2.4',
            options:      [ Options.outfile( '.xml' ), Options.skip_responses ]
        }
    end

    def add_variations( issue )
        start_tag 'variations'

        issue.variations.each_with_index do |var|
            start_tag 'variation'

            simple_tag( 'url', var['url'] )
            simple_tag( 'id', URI.encode( var['id'] ) ) if var['id']
            simple_tag( 'injected', URI.encode( var['injected'] ) ) if var['injected']
            simple_tag( 'regexp', var['regexp'].to_s ) if var['regexp']
            simple_tag( 'regexp_match', var['regexp_match'] ) if var['regexp_match']

            start_tag 'remarks'
            var.remarks.each do |commenter, remarks|
                remarks.each do |remark|
                    add_remark( commenter, remark )
                end
            end
            end_tag 'remarks'

            start_tag 'headers'
            add_headers( 'request', var['headers']['request']  )
            add_headers( 'response', var['headers']['response'] )
            end_tag 'headers'

            simple_tag( 'html', skip_responses? ? '' : Base64.encode64( var['response'].to_s ) )

            end_tag 'variation'
        end

        end_tag 'variations'
    end

end
