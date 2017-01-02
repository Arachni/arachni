=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require_relative '../option_parser'

module Arachni
module UI::CLI

class Framework

# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class OptionParser < UI::CLI::OptionParser

    attr_reader :framework

    def initialize
        super

        # Listing components can be handled here but we need a framework for that.
        @framework = Arachni::Framework.new
    end

    def authorized_by
        on( '--authorized-by EMAIL_ADDRESS',
               'E-mail address of the person who authorized the scan.',
               "(It'll make it easier on the sys-admins during log reviews.)",
               "(Will be used as a value for the 'From' HTTP request header.)"
        ) do |email_address|
            options.authorized_by = email_address
        end
    end

    def daemon_friendly
        on( '--daemon-friendly',
            'Enable this option when running the process in the background.'
        ) do |b|
            @daemon_friendly = b
        end
    end

    def daemon_friendly?
        !!@daemon_friendly
    end

    def output
        separator ''
        separator 'Output'

        on( '--output-verbose', 'Show verbose output.' ) do
            verbose_on
        end

        on( '--output-debug [LEVEL 1-4]', Integer, 'Show debugging information.' ) do |level|
            debug_on( level || 1 )
        end

        on( '--output-only-positives', 'Only output positive results.' ) do
            only_positives
        end
    end

    def scope
        separator ''
        separator 'Scope'

        on( '--scope-include-pattern PATTERN', Regexp,
            'Only include resources whose path/action matches PATTERN.',
            '(Can be used multiple times.)'
        ) do |pattern|
            options.scope.include_path_patterns << pattern
        end

        on( '--scope-include-subdomains', 'Follow links to subdomains.',
            "(Default: #{!!options.scope.include_subdomains})"
        ) do
            options.scope.include_subdomains = true
        end

        on( '--scope-exclude-pattern PATTERN', Regexp,
               'Exclude resources whose path/action matches PATTERN.',
               '(Can be used multiple times.)'
        ) do |pattern|
            options.scope.exclude_path_patterns << pattern
        end

        on( '--scope-exclude-file-extensions EXTENSION,EXTENSION2,..',
            'Exclude resources with the specified extensions.'
        ) do |extensions|
            options.scope.exclude_file_extensions = extensions.split(',')
        end

        on( '--scope-exclude-content-pattern PATTERN', Regexp,
               'Exclude pages whose content matches PATTERN.',
               '(Can be used multiple times.)'
        ) do |pattern|
            options.scope.exclude_content_patterns << pattern
        end

        on( '--scope-exclude-binaries',
            'Exclude non text-based pages.',
            '(Binary content can confuse passive checks that perform pattern matching.)'
        ) do
            options.scope.exclude_binaries = true
        end

        on( '--scope-redundant-path-pattern PATTERN:LIMIT',
               'Limit crawl on redundant pages like galleries or catalogs.',
               '(URLs matching PATTERN will be crawled LIMIT amount of times.)',
               '(Can be used multiple times.)'
        ) do |rule|
            pattern, counter = rule.split( ':', 2 )
            options.scope.redundant_path_patterns[ Regexp.new( pattern ) ] =
                Integer( counter )
        end

        on( '--scope-auto-redundant [LIMIT]', Integer,
               'Only follow URLs with identical query parameter names LIMIT amount of times.',
               '(Default: 10)'
        ) do |counter|
            options.scope.auto_redundant_paths = counter || 10
        end

        on( '--scope-directory-depth-limit LIMIT', Integer,
               'Directory depth limit.',
               '(Default: inf)',
               '(How deep Arachni should go into the site structure.)'
        ) do |depth|
            options.scope.directory_depth_limit = depth
        end

        on( '--scope-page-limit LIMIT', Integer,
               'How many pages to crawl and audit.',
               '(Default: inf)'
        ) do |limit|
            options.scope.page_limit = limit
        end

        on( '--scope-extend-paths FILE',
               'Add the paths in FILE to the ones discovered by the crawler.',
               '(Can be used multiple times.)'
        ) do |file|
            options.scope.extend_paths |= paths_from_file( file )
        end

        on( '--scope-restrict-paths FILE',
               'Use the paths in FILE instead of crawling.',
               '(Can be used multiple times.)'
        ) do |file|
            options.scope.restrict_paths |= paths_from_file( file )
        end

        on( '--scope-url-rewrite PATTERN:SUBSTITUTION',
            'Rewrite URLs based on the given PATTERN and SUBSTITUTION.',
            'To convert:  http://example.com/articles/some-stuff/23 to http://example.com/articles.php?id=23',
            'Use:         articles/[\w-]+/(\d+):articles.php?id=\1'
        ) do |rule|
            pattern, substitution = rule.split( ':', 2 )
            options.scope.url_rewrites[ Regexp.new( pattern ) ] =
                substitution
        end

        on( '--scope-dom-depth-limit LIMIT', Integer,
               'How deep to go into the DOM tree of each page, for pages with JavaScript code.',
               "(Default: #{options.scope.dom_depth_limit})",
               "(Setting it to '0' will disable browser analysis.)"
        ) do |limit|
            options.scope.dom_depth_limit = limit
        end

        on( '--scope-dom-event-limit LIMIT', Integer,
            'How many DOM events to trigger for each DOM depth, for pages with JavaScript code.',
            "(Default: #{options.scope.dom_event_limit.nil? ? 'inf' : options.scope.dom_event_limit })",
        ) do |limit|
            options.scope.dom_event_limit = limit
        end

        on( '--scope-https-only', 'Forces the system to only follow HTTPS URLs.',
            "(Default: #{!!options.scope.https_only})"
        ) do
            options.scope.https_only = true
        end
    end

    def audit
        separator ''
        separator 'Audit'

        on( '--audit-links', 'Audit links.' ) do
            options.audit.links = true
        end

        on( '--audit-forms', 'Audit forms.' ) do
            options.audit.forms = true
        end

        on( '--audit-cookies', 'Audit cookies.' ) do
            options.audit.cookies = true
        end

        on( '--audit-cookies-extensively',
               'Submit all links and forms of the page along with the cookie permutations.',
               '(*WARNING*: This will severely increase the scan-time.)'
        ) do
            options.audit.cookies_extensively = true
        end

        on( '--audit-headers', 'Audit headers.' ) do
            options.audit.headers = true
        end

        on( '--audit-link-template TEMPLATE', Regexp,
            'Regular expression with named captures to use to extract input information from generic paths.',
            "To extract the 'input1' and 'input2' inputs from:",
            '  http://example.com/input1/value1/input2/value2',
            'Use:',
            '  input1/(?<input1>\w+)/input2/(?<input2>\w+)',
            '(Can be used multiple times.)'
        ) do |pattern|
            # We merge this way to enforce validation from the options group.
            options.audit.link_templates |= [pattern]
        end

        on( '--audit-jsons', 'Audit JSON request inputs.' ) do
            options.audit.jsons = true
        end

        on( '--audit-xmls', 'Audit XML request inputs.' ) do
            options.audit.xmls = true
        end

        on( '--audit-ui-inputs', 'Audit orphan <input> elements with events.' ) do
            options.audit.ui_inputs = true
        end

        on( '--audit-ui-forms', 'Audit UI Forms.',
            'Input and button groups that do not belong to a parent <form> element.' ) do
            options.audit.ui_forms = true
        end

        on( '--audit-parameter-names',
            'Inject payloads into parameter names.'
        ) do
            options.audit.parameter_names = true
        end

        on( '--audit-with-raw-payloads',
            'Inject payloads with and without HTTP encoding.'
        ) do
            options.audit.with_raw_payloads = true
        end

        on( '--audit-with-extra-parameter',
            'Inject payloads into extra element parameters.'
        ) do
            options.audit.with_extra_parameter = true
        end

        on( '--audit-with-both-methods',
               'Audit elements with both GET and POST requests.',
               '(*WARNING*: This will severely increase the scan-time.)'
        ) do
            options.audit.with_both_http_methods = true
        end

        on( '--audit-exclude-vector PATTERN', Regexp,
               'Exclude input vectors whose name matches PATTERN.',
               '(Can be used multiple times.)' ) do |name|
            options.audit.exclude_vector_patterns << name
        end

        on( '--audit-include-vector PATTERN', Regexp,
            'Include only input vectors whose name matches PATTERN.',
            '(Can be used multiple times.)' ) do |name|
            options.audit.include_vector_patterns << name
        end
    end

    def http
        separator ''
        separator 'HTTP'

        on( '--http-user-agent USER_AGENT',
            "Value for the 'User-Agent' HTTP request header.",
            "(Default: #{options.http.user_agent})"
        ) do |user_agent|
            options.http.user_agent = user_agent
        end

        on( '--http-request-concurrency MAX_CONCURRENCY', Integer,
               'Maximum HTTP request concurrency.',
               "(Default: #{options.http.request_concurrency})",
               '(Be careful not to kill your server.)',
               '(*NOTE*: If your scan seems unresponsive try lowering the limit.)'
        ) do |concurrency|
            options.http.request_concurrency = concurrency
        end

        on( '--http-request-timeout TIMEOUT', Integer,
            'HTTP request timeout in milliseconds.',
            "(Default: #{options.http.request_timeout})"
        ) do |username|
            options.http.request_timeout = username
        end

        on( '--http-request-redirect-limit LIMIT', Integer,
            'Maximum amount of redirects to follow for each HTTP request.',
            "(Default: #{options.http.request_redirect_limit})"
        ) do |limit|
            options.http.request_redirect_limit = limit
        end

        on( '--http-request-queue-size QUEUE_SIZE', Integer,
               'Maximum amount of requests to keep in the queue.',
               'Bigger size means better scheduling and better performance,',
               'smaller means less RAM consumption.',
               "(Default: #{options.http.request_queue_size})"
        ) do |size|
            options.http.request_queue_size = size
        end

        on( '--http-request-header NAME=VALUE',
            'Specify custom headers to be included in the HTTP requests.',
            '(Can be used multiple times.)'
        ) do |user_agent|
            header, val = user_agent.split( '=', 2 )
            options.http.request_headers[header] = val
        end

        on( '--http-response-max-size LIMIT', Integer,
               'Do not download response bodies larger than the specified LIMIT, in bytes.',
               "(Default: #{options.http.response_max_size})"
        ) do |size|
            options.http.response_max_size = size
        end

        on( '--http-cookie-jar COOKIE_JAR_FILE',
               'Netscape-styled HTTP cookiejar file.'
        ) do |file|
            options.http.cookie_jar_filepath = file
        end

        on( '--http-cookie-string COOKIE',
               "Cookie representation as a 'Set-Cookie' HTTP response header.",
               'Example: my_cookie=my_value; Path=/, other_cookie=other_value; Path=/test'
        ) do |cookie|
            options.http.cookie_string = cookie
        end

        on( '--http-authentication-username USERNAME',
               'Username for HTTP authentication.' ) do |username|
            options.http.authentication_username = username
        end

        on( '--http-authentication-password PASSWORD',
               'Password for HTTP authentication.' ) do |password|
            options.http.authentication_password = password
        end

        on( "--http-authentication-type #{OptionGroups::HTTP::AUTHENTICATION_TYPES.join(',')}",
            'HTTP authentication type.', '(Default: auto)' ) do |type|
            options.http.authentication_type = type
        end

        on( '--http-proxy ADDRESS:PORT', 'Proxy to use.' ) do |url|
            options.http.proxy = url
            options.http.proxy_host, options.http.proxy_port = url.split( ':', 2 )
        end

        on( '--http-proxy-authentication USERNAME:PASSWORD',
               'Proxy authentication credentials.' ) do |credentials|
            options.http.proxy_username, options.http.proxy_password = credentials.split( ':', 2 )
        end

        on( "--http-proxy-type #{OptionGroups::HTTP::PROXY_TYPES.join(',')}",
               OptionGroups::HTTP::PROXY_TYPES,
               'Proxy type.', '(Default: auto)'
        ) do |type|
            options.http.proxy_type = type
        end

        on( '--http-ssl-verify-peer', 'Verify SSL peer.', '(Default: false)' ) do
            options.http.ssl_verify_peer = true
        end

        on( '--http-ssl-verify-host', 'Verify SSL host.', '(Default: false)' ) do
            options.http.ssl_verify_host = true
        end

        on( '--http-ssl-certificate PATH', 'SSL certificate to use.' ) do |file|
            options.http.ssl_certificate_filepath = file
        end

        on( "--http-ssl-certificate-type #{OptionGroups::HTTP::SSL_CERTIFICATE_TYPES.join(',')}",
            OptionGroups::HTTP::SSL_CERTIFICATE_TYPES,
            'SSL certificate type.'
        ) do |type|
            options.http.ssl_certificate_type = type
        end

        on( '--http-ssl-key PATH', 'SSL private key to use.' ) do |file|
            options.http.ssl_key_filepath = file
        end

        on( "--http-ssl-key-type #{OptionGroups::HTTP::SSL_KEY_TYPES.join(',')}",
            OptionGroups::HTTP::SSL_KEY_TYPES,
            'SSL key type.'
        ) do |type|
            options.http.ssl_key_type = type
        end

        on( '--http-ssl-key-password PASSWORD',
            'Password for the SSL private key.' ) do |pass|
            options.http.ssl_key_password = pass
        end

        on( '--http-ssl-ca PATH',
            'File holding one or more certificates with which to verify the peer.' ) do |file|
            options.http.ssl_ca_filepath = file
        end

        on( '--http-ssl-ca-directory PATH',
            'Directory holding multiple certificate files with which to verify the peer.' ) do |path|
            options.http.ssl_ca_directory = path
        end

        on( "--http-ssl-version #{OptionGroups::HTTP::SSL_VERSIONS.join(',')}",
            OptionGroups::HTTP::SSL_VERSIONS,
            'SSL version to use.'
        ) do |type|
            options.http.ssl_version = type
        end
    end

    def checks
        separator ''
        separator 'Checks'

        on( '--checks-list [GLOB]',
               'List available checks based on the provided glob.',
               '(If no glob is provided all checks will be listed.)'
        ) do |pattern|
            list_checks( framework.list_checks( pattern ) )
            exit
        end

        on( '--checks CHECK,CHECK2,...',
               'Comma separated list of checks to load.',
               "    Checks are referenced by their filename without the '.rb' extension, use '--checks-list' to list all.",
               "    Use '*' as a check name to load all checks or as a wildcard, like so:",
               '        xss*   to load all XSS checks',
               '        sql_injection*  to load all SQL injection checks',
               '        etc.',
               '',
               '    You can exclude checks by prefixing their name with a minus sign:',
               '        --checks=*,-backup_files,-xss',
               "    The above will load all checks except for the 'backup_files' and 'xss' checks.",
               '',
               '    Or mix and match:',
               '        -xss*   to unload all XSS checks.'
        ) do |checks|
            options.checks |= checks.split( ',' )
        end
    end

    def plugins
        separator ''
        separator 'Plugins'

        on( '--plugins-list [GLOB]',
               'List available plugins based on the provided glob.',
               '(If no glob is provided all plugins will be listed.)'
        ) do |pattern|
            list_plugins( framework.list_plugins( pattern ) )
            exit
        end

        on( "--plugin 'PLUGIN:OPTION=VALUE,OPTION2=VALUE2'",
               "PLUGIN is the name of the plugin as displayed by '--plugins-list'.",
               "(Plugins are referenced by their filename without the '.rb' extension, use '--plugins-list' to list all.)",
               '(Can be used multiple times.)'
        ) do |plugin|
            prepare_component_options( options.plugins, plugin )
        end
    end

    def platforms
        separator ''
        separator 'Platforms'

        on( '--platforms-list', 'List available platforms.' ) do
            list_platforms( framework.list_platforms )
            exit
        end

        on( '--platforms-no-fingerprinting',
               'Disable platform fingerprinting.',
               '(By default, the system will try to identify the deployed server-side platforms automatically',
               'in order to avoid sending irrelevant payloads.)'
        ) do
            options.no_fingerprinting = true
        end

        on( '--platforms PLATFORM,PLATFORM2,...',
               'Comma separated list of platforms (by shortname) to audit.',
               '(The given platforms will be used *in addition* to fingerprinting. In order to restrict the audit to',
               "these platforms enable the '--platforms-no-fingerprinting' option.)"
        ) do |platforms|
            options.platforms |= platforms.split( ',' )
        end
    end

    def session
        separator ''
        separator 'Session'

        on( '--session-check-url URL', String,
               'URL to use to verify that the scanner is still logged in ' <<
                   'to the web application.',
               "(Requires 'session-check-pattern'.)"
        ) do |url|
            options.session.check_url = url.to_s
        end

        on( '--session-check-pattern PATTERN', Regexp,
               "Pattern used against the body of the 'session-check-url'" <<
                   ' to verify that the scanner is still logged in to the web application.',
               "(Requires 'session-check-url'.)"
        ) do |pattern|
            options.session.check_pattern = pattern
        end
    end

    def input
        separator ''
        separator 'Input'

        on( '--input-value PATTERN:VALUE',
            'PATTERN to match against input names and VALUE to use for them.',
            '(Can be used multiple times.)'
        ) do |rule|
            pattern, value = rule.split( ':', 2 )
            options.input.values[Regexp.new(pattern)] = value
        end

        on( '--input-values-file FILE',
            'YAML file containing a Hash object with regular expressions,' <<
                ' to match against input names, as keys and input values as values.'
        ) do |file|
            options.input.update_values_from_file( file )
        end

        on( '--input-without-defaults', 'Do not use the system default input values.' ) do
            options.input.without_defaults = true
        end

        on( '--input-force', 'Fill-in even non-empty inputs.' ) do
            options.input.force = true
        end
    end

    def browser_cluster
        separator ''
        separator 'Browser cluster'

        on( '--browser-cluster-local-storage FILE',
            "Sets the browsers' local storage using the JSON data in FILE."
        ) do |file|
            options.browser_cluster.local_storage = ::JSON.load( IO.read( file ) )
        end

        on( '--browser-cluster-wait-for-element PATTERN:CSS',
            'Wait for element matching CSS to appear when visiting a page whose' <<
            ' URL matches the PATTERN.'
        ) do |rule|
            pattern, css = rule.split( ':', 2 )
            options.browser_cluster.wait_for_elements[ Regexp.new( pattern ) ] =
                css
        end

        on( '--browser-cluster-pool-size SIZE', Integer,
            'Amount of browser workers to keep in the pool and put to work.',
            "(Default: #{options.browser_cluster.pool_size})"
        ) do |pool_size|
            options.browser_cluster.pool_size = pool_size
        end

        on( '--browser-cluster-job-timeout SECONDS', Integer,
            'Maximum allowed time for each job.',
            "(Default: #{options.browser_cluster.job_timeout})"
        ) do |job_timeout|
            options.browser_cluster.job_timeout = job_timeout
        end

        on( '--browser-cluster-worker-time-to-live LIMIT', Integer,
            'Re-spawn the browser of each worker every LIMIT jobs.',
            "(Default: #{options.browser_cluster.worker_time_to_live})"
        ) do |worker_time_to_live|
            options.browser_cluster.worker_time_to_live = worker_time_to_live
        end

        on( '--browser-cluster-ignore-images', 'Do not load images.' ) do |ignore_images|
            options.browser_cluster.ignore_images = ignore_images
        end

        on( '--browser-cluster-screen-width', Integer,
            'Browser screen width.',
            "(Default: #{options.browser_cluster.screen_width})"
        ) do |width|
            options.browser_cluster.screen_width = width
        end

        on( '--browser-cluster-screen-height', Integer,
            'Browser screen height.',
            "(Default: #{options.browser_cluster.screen_height})"
        ) do |height|
            options.browser_cluster.screen_height = height
        end
    end

    def profiles
        separator ''
        separator 'Profiles'

        on( '--profile-save-filepath FILEPATH', String,
               'Save the current configuration profile/options to FILEPATH.'
        ) do |filepath|
            @save_profile_path = filepath
        end

        on( '--profile-load-filepath FILEPATH', String,
               'Load a configuration profile from FILEPATH.'
        ) do |filepath|
            load_profile( filepath )
        end
    end

    def report
        separator ''
        separator 'Report'

        on( '--report-save-path PATH', String,
            'Directory or file path where to store the scan report.',
            'You can use the generated file to create reports in several ' +
                "formats with the 'arachni_reporter' executable."
        ) do |path|
            options.datastore.report_path = path
        end
    end

    def snapshot
        separator ''
        separator 'Snapshot'

        on( '--snapshot-save-path PATH', String,
            'Directory or file path where to store the snapshot of a suspended scan.',
            'You can use the generated file to resume the scan with the \'arachni_restore\' executable.'
        ) do |path|
            options.snapshot.save_path = path
        end
    end

    def timeout
        separator ''
        separator 'Timeout'

        on( '--timeout HOURS:MINUTES:SECONDS',
            'Stop the scan after the given duration is exceeded.'
        ) do |time|
            @timeout = Arachni::Utilities.hms_to_seconds( time )
        end
    end

    def timeout_suspend
        on( '--timeout-suspend',
            'Suspend after the timeout.',
            'You can use the generated file to resume the scan with the \'arachni_restore\' executable.'
        ) do
            @timeout_suspend = true
        end
    end

    def timeout_suspend?
        !!@timeout_suspend
    end

    def get_timeout
        @timeout
    end

    def after_parse
        if @save_profile_path
            save_profile( @save_profile_path )
            exit 0
        end

        options.url = ARGV.shift
    rescue Options::Error::InvalidURL => e
        print_bad e
        exit
    end

    def validate
        validate_timeout
        validate_report_path
        validate_snapshot_save_path
        validate_session
        validate_url
    end

    def validate_url
        return if options.url

        print_bad 'Missing URL argument.'
        exit 1
    end

    def validate_timeout
        return if !@timeout || @timeout > 0

        print_bad 'Invalid timeout value.'
        exit 1
    end

    def validate_snapshot_save_path
        snapshot_path = options.snapshot.save_path
        return if valid_save_path?( snapshot_path )

        print_bad "Snapshot path does not exist: #{snapshot_path}"
        exit 1
    end

    def validate_report_path
        report_path = options.datastore.report_path
        return if valid_save_path?( report_path )

        print_bad "Report path does not exist: #{report_path}"
        exit 1
    end

    def validate_session
        if (!options.session.check_url && options.session.check_pattern) ||
            (options.session.check_url && !options.session.check_pattern)
            print_bad "Both '--session-check-url' and '--session-check-pattern'" <<
                            ' options are required.'
            exit 1
        end
    end

    def valid_save_path?( path )
        !path || File.directory?( path ) || !path.end_with?( '/' )
    end

    def banner
        "#{super} URL"
    end

end
end
end
end
