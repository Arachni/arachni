=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'zip'
require 'kramdown'
require 'loofah'
require 'coderay'
require 'json'
require 'erb'
require 'base64'
require 'cgi'
require 'fileutils'

# Creates an HTML report with scan results.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class Arachni::Reporters::HTML < Arachni::Reporter::Base

    TEMPLATE_FILE = File.dirname( __FILE__ ) + '/html/default.erb'
    TEMPLATE_DIR  = File.dirname( TEMPLATE_FILE ) + '/' +
        File.basename( TEMPLATE_FILE, '.erb' ) + '/'

    OWASP_TOP_10_URL  = 'https://www.owasp.org/index.php/Top_10_2013-Top_10'
    OWASP_TOP_10_DATA = {
        'A1-Injection' => {
            code:       'A1',
            description: %q{
Injection flaws, such as SQL, OS, and LDAP injection occur when untrusted data
is sent to an interpreter as part of a command or query. The attacker’s hostile
data can trick the interpreter into executing unintended commands or accessing
data without proper authorization.
},
            url:         'https://www.owasp.org/index.php/Top_10_2013-A1-Injection',
            checks:      [
                :command_injection,
                :command_injection_php_input_wrapper,
                :command_injection_timing,
                :ldap_injection,
                :no_sql_injection,
                :no_sql_injection_differential,
                :os_cmd_injection,
                :os_cmd_injection_timing,
                :sql_injection,
                :sql_injection_differential,
                :sql_injection_timing,
                :xpath_injection,
                :xxe
            ]
        },
        'A2-Broken Authentication and Session Management' => {
            code:        'A2',
            description: %q{
Application functions related to authentication and session management are often
not implemented correctly, allowing attackers to compromise passwords, keys, or
session tokens, or to exploit other implementation flaws to assume other users’
identities.
},
            url:         'https://www.owasp.org/index.php/Top_10_2013-A2-Broken_Authentication_and_Session_Management',
            checks:      [
                :session_fixation
            ]
        },
        'A3-Cross-Site Scripting (XSS)' => {
            code:        'A3',
            description: %q{
XSS flaws occur whenever an application takes untrusted data and sends it to a
web browser without proper validation or escaping. XSS allows attackers to
execute scripts in the victim’s browser which can hijack user sessions, deface
web sites, or redirect the user to malicious sites.
},
            url:         'https://www.owasp.org/index.php/Top_10_2013-A3-Cross-Site_Scripting_(XSS)',
            checks:      [
                :xss,
                :xss_dom,
                :xss_dom_inputs,
                :xss_dom_script_context,
                :xss_event,
                :xss_path,
                :xss_script_context,
                :xss_tag
            ]
        },
        'A5-Security Misconfiguration' => {
            code:        'A5',
            description: %q{
Good security requires having a secure configuration defined and deployed for
the application, frameworks, application server, web server, database server,
and platform. Secure settings should be defined, implemented, and maintained,
as defaults are often insecure. Additionally, software should be kept up to date.
},
            url:         'https://www.owasp.org/index.php/Top_10_2013-A5-Security_Misconfiguration',
            checks:      [
                :cookie_set_for_parent_domain,
                :hsts,
                :insecure_cors_policy,
                :htaccess_limit,
                :http_put,
                :insecure_client_access_policy,
                :insecure_cross_Domain_policy_access,
                :insecure_cross_Domain_policy_headers,
                :origin_spood_access_restriction_bypass,
                :xst
            ]
        },
        'A6-Sensitive Data Exposure' => {
            code:        'A6',
            description: %q{
Many web applications do not properly protect sensitive data, such as credit
cards, tax IDs, and authentication credentials. Attackers may steal or modify
such weakly protected data to conduct credit card fraud, identity theft, or other
crimes. Sensitive data deserves extra protection such as encryption at rest or
in transit, as well as special precautions when exchanged with the browser.
},
            url:         'https://www.owasp.org/index.php/Top_10_2013-A6-Sensitive_Data_Exposure',
            checks:      [
                :backup_directories,
                :backup_files,
                :credit_card,
                :cvs_svn_users,
                :private_ip,
                :ssn
            ]
        },
        'A8-Sensitive Data Exposure' => {
            code:        'A8',
            description: %q{
A CSRF attack forces a logged-on victim’s browser to send a forged HTTP request,
including the victim’s session cookie and any other automatically included
authentication information, to a vulnerable web application. This allows the
attacker to force the victim’s browser to generate requests the vulnerable
application thinks are legitimate requests from the victim.
},
            url:         'https://www.owasp.org/index.php/Top_10_2013-A8-Cross-Site_Request_Forgery_(CSRF)',
            checks:      [
                :csrf
            ]
        },
        'A10-Unvalidated Redirects and Forwards' => {
            code:        'A10',
            description: %q{
Web applications frequently redirect and forward users to other pages and websites,
and use untrusted data to determine the destination pages. Without proper validation,
attackers can redirect victims to phishing or malware sites, or use forwards to
access unauthorized pages.
},
            url:         'https://www.owasp.org/index.php/Top_10_2013-A10-Unvalidated_Redirects_and_Forwards',
            checks:      [
                :unvalidated_redirect,
                :unvalidated_redirect_dom
            ]
        }
    }

    module TemplateUtilities

        def base64_encode( string )
            Base64.encode64( string ).gsub( /\n/, '' )
        end

        def normalize( str )
            str.to_s.recode
        end

        def md( markdown )
            html = Kramdown::Document.new( markdown ).to_html.recode
            Loofah.fragment( html ).scrub!(:prune).to_s
        end

        def key_to_words( k )
            k.to_s.capitalize.gsub( '_', ' ' )
        end

        def code_highlight( code, language = :html, options = {} )
            return if !code

            lines = CodeRay.scan( code.recode, language ).
                html( css: :style ).lines.to_a

            if options[:from]
                from = [0, options[:from]].max
            else
                from = 0
            end

            if options[:to]
                to = [lines.size, options[:to]].min
            else
                to = lines.size - 1
            end

            code = '<div class="code-container"><table class="CodeRay"><tbody><tr><td class="line-numbers"><pre>'

            from.upto(to) do |i|
                if options[:anchor_id]
                    line = "<a href='#{id_to_location "#{options[:anchor_id]}-#{i}"}'>#{i}</a>"
                else
                    line = "#{i}"
                end

                if options[:breakpoint] && options[:breakpoint] == i
                    code << "<span class='breakpoint'>#{line}</span>"
                else
                    code << line
                end

                code << "\n"
            end

            code << '</pre></td><td class="code"><pre>'

            from.upto(to) do |i|
                line = "<span id='#{options[:anchor_id]}-#{i}'>#{lines[i]}</span>"

                if options[:breakpoint] && options[:breakpoint] == i
                    code << "<span class='breakpoint'>#{line}</span>"
                else
                    code << line.to_s
                end
            end

            code + '</pre></td></tr></tbody></table></div>'
        end

        def highlight_proof( string, proof )
            proof  = proof.to_s.recode
            string = string.to_s.recode

            return escapeHTML( string ) if proof.to_s.empty?
            return escapeHTML( string ) if !string.include?( proof )

            escaped_proof         = escapeHTML( proof )
            escaped_response_body = escapeHTML( string )

            escaped_response_body.gsub(
                escaped_proof,
                "<span class=\"issue-proof-highlight\">#{escaped_proof}</span>"
            )
        end

        def data_dump( data )
            ap = AwesomePrint::Inspector.new( plain: true, html: true )
            "<pre class='data-dump'>#{ap.awesome( data )}</pre>"
        end

        # Carefully escapes HTML and converts to UTF-8 while removing
        # invalid character sequences.
        def escapeHTML( str )
            CGI.escapeHTML( normalize( str ) )
        end

        def highlight_issue_page_body( issue, span_class )
            return escapeHTML( issue.page.body ) if !issue.page.body.include?( issue.proof )

            escaped_proof         = escapeHTML( issue.proof )
            escaped_response_body = escapeHTML( issue.page.body )

            escaped_response_body.gsub(
                escaped_proof,
                "<span class=\"#{span_class}\">#{escaped_proof}</span>"
            )
        end

        def issue_location( issue )
            id_to_location( issue_id( issue ) )
        end

        def issue_id( issue )
            issue = report.issue_by_digest( issue.digest )

            "issues-#{'un' if issue.untrusted?}trusted-severity-" <<
                "#{issue.severity}-#{issue.check[:shortname]}-#{issue.digest}"
        end

        def id_to_location( id )
            "#!/#{id.gsub( '-', '/' )}"
        end

        def erb( tpl, params = {} )
            scope = TemplateScope.new( params )

            tpl = tpl.to_s + '.erb' if tpl.is_a?( Symbol )

            path = File.exist?( tpl ) ? tpl : TEMPLATE_DIR + tpl

            ERB.new( IO.read( path ).recode ).result( scope.get_binding )
        rescue
            ap tpl
            raise
        end
    end

    include TemplateUtilities

    class TemplateScope
        include TemplateUtilities

        ISSUES_URL = 'https://github.com/Arachni/arachni/issues'

        def initialize( params = {} )
            update params
            update self.class.global_data
        end

        def update( params )
            params.each { |name, value| self[name] = value }
            self
        end

        def []=( name, value )
            self.class.send( :attr_accessor, name )
            instance_variable_set( "@#{name.to_s}", value )
            self
        end

        def prep_description( str )
            escapeHTML Arachni::Reporters::HTML.prep_description( str )
        end

        def get_plugin_info( name )
            report.plugins[name.to_sym]
        end

        def js_multiline( str )
            "\"" + normalize( str ).gsub( "\n", '\n' ) + "\""
        end

        def get_binding
            binding
        end

        def self.global_data=( data )
            @global_data = data
        end

        def self.global_data
            @global_data
        end
    end

    def global_data
        grouped_issues = {
            trusted:   {},
            untrusted: {}
        }

        Arachni::Issue::Severity::ORDER.each do |severity|
            by_severity = report.issues.select { |i| i.severity.to_sym == severity }
            next if by_severity.empty?

            by_name = {}
            by_severity.each do |issue|
                by_name[issue.name] ||= []
                by_name[issue.name] << issue
            end
            next if by_name.empty?

            grouped_issues[:trusted][by_severity.first.severity] =
                by_name.inject({}) do |h, (name, issues)|
                    i = issues.select(&:trusted?)
                    next h if i.empty?

                    h[name] = i
                    h
                end

            grouped_issues[:untrusted][by_severity.first.severity] =
                by_name.inject({}) do |h, (name, issues)|
                    i = issues.select(&:untrusted?)
                    next h if i.empty?

                    h[name] = i
                    h
                end

            [:trusted, :untrusted].each do |t|
                if grouped_issues[t][by_severity.first.severity].empty?
                    grouped_issues[t].delete by_severity.first.severity
                end
            end
        end

        [:trusted, :untrusted].each do |t|
            grouped_issues.delete( t ) if grouped_issues[t].empty?
        end

        prepare_data.merge(
            report:         report,
            grouped_issues: grouped_issues,
            plugins:        format_plugin_results
        )
    end

    # Runs the HTML report.
    def run
        FileUtils.rm_rf outfile

        print_line
        print_status 'Creating HTML report...'

        TemplateScope.global_data = global_data

        tmpdir = "#{Arachni::Options.paths.tmpdir}/#{generate_token}/"

        FileUtils.rm_rf tmpdir
        FileUtils.mkdir_p tmpdir

        FileUtils.mkdir_p "#{tmpdir}/js/lib"
        FileUtils.mkdir_p "#{tmpdir}/css/lib"

        FileUtils.cp_r "#{TEMPLATE_DIR}/fonts", "#{tmpdir}/"
        FileUtils.cp_r "#{TEMPLATE_DIR}/js/lib", "#{tmpdir}/js/"
        FileUtils.cp_r "#{TEMPLATE_DIR}/css/lib", "#{tmpdir}/css/"

        %w(js/helpers.js js/init.js.erb js/charts.js.erb js/configuration.js.erb
            css/main.css).each do |f|
            if f.end_with? '.erb'
                IO.write( "#{tmpdir}/#{f.split('.erb').first}", erb( "#{TEMPLATE_DIR}/#{f}" ) )
            else
                FileUtils.cp( "#{TEMPLATE_DIR}/#{f}" , "#{tmpdir}/#{f}" )
            end
        end

        IO.write( "#{tmpdir}/index.html", erb( TEMPLATE_FILE ) )

        compress( tmpdir, outfile )
        FileUtils.rm_rf tmpdir

        print_status "Saved in '#{outfile}'."
    end

    def self.info
        {
            name:         'HTML',
            description:  %q{Exports the audit results as a compressed HTML report.},
            content_type: 'application/zip',
            author:       'Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>',
            version:      '0.4.3',
            options:      [
                Options.outfile( '.html.zip' ),
                Options.skip_responses
            ]
        }
    end

    private

    def compress( directory, archive )
        Zip::File.open( archive, Zip::File::CREATE ) do |zipfile|
            Dir[File.join(directory, '**', '**')].each do |file|
                zipfile.add( file.sub( directory, '' ), file )
            end
        end

        archive
    end

    def self.prep_description( str )
        placeholder =  '--' + rand( 1000 ).to_s + '--'
        cstr = str.gsub( /^\s*$/xm, placeholder )
        cstr.gsub!( /^\s*/xm, '' )
        cstr.gsub!( placeholder, "\n" )
        cstr.chomp
    end

    def prepare_data
        graph_data = {
            severities:       {
                Severity::HIGH.to_sym          => 0,
                Severity::MEDIUM.to_sym        => 0,
                Severity::LOW.to_sym           => 0,
                Severity::INFORMATIONAL.to_sym => 0
            },
            severity_for_issue: {},
            severity_index_for_issue: {},
            severity_regions: {},
            issues:           {},
            issues_shortnames: Set.new,
            trusted_issues:   {},
            untrusted_issues: {},
            elements:         {
                Element::Form.type   => 0,
                Element::Form::DOM.type   => 0,
                Element::Link.type   => 0,
                Element::Link::DOM.type   => 0,
                Element::Cookie.type => 0,
                Element::Cookie::DOM.type => 0,
                Element::LinkTemplate.type => 0,
                Element::LinkTemplate::DOM.type => 0,
                Element::Header.type => 0,
                Element::Body.type   => 0,
                Element::Path.type   => 0,
                Element::Server.type => 0,
                Element::GenericDOM.type  => 0,
                Element::JSON.type        => 0,
                Element::XML.type         => 0,
                Element::UIInput::DOM.type  => 0,
                Element::UIForm::DOM.type => 0
            },
            verification:     {
                'Yes' => 0,
                'No'  => 0
            },
            trust:            {
                'Trusted'   => 0,
                'Untrusted' => 0
            }
        }

        total_severities = 0
        total_elements   = 0

        has_trusted_issues   = false
        has_untrusted_issues = false
        last_severity        = nil

        report.issues.each.with_index do |issue, i|
            graph_data[:severities][issue.severity.to_sym] += 1
            total_severities += 1

            graph_data[:issues][issue.name] ||= 0
            graph_data[:issues][issue.name] += 1

            graph_data[:elements][issue.vector.class.type] += 1
            total_elements += 1

            verification = issue.untrusted? ? 'Yes' : 'No'
            graph_data[:verification][verification] += 1

            graph_data[:untrusted_severities] ||= {}
            graph_data[:untrusted_severities][issue.severity.to_sym] ||= 0

            graph_data[:trusted_severities] ||= {}
            graph_data[:trusted_severities][issue.severity.to_sym] ||= 0

            graph_data[:trusted_issues][issue.name]   ||= 0
            graph_data[:untrusted_issues][issue.name] ||= 0

            graph_data[:issues_shortnames] << issue.check[:shortname]
            graph_data[:severity_for_issue][issue.check[:shortname]] = issue.severity.to_s

            new_region = !graph_data[:severity_regions].include?( issue.severity.to_sym )

            graph_data[:severity_regions][issue.severity.to_sym] ||= {}
            graph_data[:severity_regions][issue.severity.to_sym][:class]  =
                "severity-#{issue.severity.to_sym}"
            graph_data[:severity_regions][issue.severity.to_sym][:start] ||=
                graph_data[:issues].size - 1

            if new_region && last_severity
                graph_data[:severity_regions][last_severity][:end] =
                    graph_data[:issues].size - 2
            end
            last_severity = issue.severity.to_sym

            graph_data[:severity_index_for_issue][issue.name] =
                Issue::Severity::ORDER.reverse.index( issue.severity.to_sym ) + 1

            if issue.trusted?
                has_trusted_issues = true
                graph_data[:trust]['Trusted'] += 1
                graph_data[:trusted_severities][issue.severity.to_sym] += 1
                graph_data[:trusted_issues][issue.name] += 1
            else
                has_untrusted_issues = true
                graph_data[:trust]['Untrusted'] += 1
                graph_data[:untrusted_severities][issue.severity.to_sym] += 1
                graph_data[:untrusted_issues][issue.name]  += 1
            end
        end

        graph_data[:issues_shortnames] = graph_data[:issues_shortnames].to_a
        graph_data[:severity_regions]  = graph_data[:severity_regions].values

        {
            graph_data:           graph_data,
            total_severities:     total_severities,
            total_elements:       total_elements,
            has_trusted_issues:   has_trusted_issues,
            has_untrusted_issues: has_untrusted_issues
        }
    end

end
