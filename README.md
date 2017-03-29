# Arachni - Web Application Security Scanner Framework

<table>
    <tr>
        <th>Version</th>
        <td>1.5.1</td>
    </tr>
    <tr>
        <th>Homepage</th>
        <td><a href="http://www.arachni-scanner.com">http://arachni-scanner.com</a></td>
    </tr>
    <tr>
        <th>Blog</th>
        <td><a href="http://www.arachni-scanner.com/blog">http://arachni-scanner.com/blog</a></td>
    <tr>
        <th>Github</th>
        <td><a href="https://github.com/Arachni/arachni">http://github.com/Arachni/arachni</a></td>
     <tr/>
    <tr>
        <th>Documentation</th>
        <td><a href="https://github.com/Arachni/arachni/wiki">https://github.com/Arachni/arachni/wiki</a></td>
    </tr>
    <tr>
        <th>Code Documentation</th>
        <td><a href="http://rubydoc.info/github/Arachni/arachni">http://rubydoc.info/github/Arachni/arachni</a></td>
    </tr>
    <tr>
        <th>Support</th>
        <td><a href="http://support.arachni-scanner.com">http://support.arachni-scanner.com</a></td>
    </tr>
    <tr>
       <th>Author</th>
       <td><a href="mailto:tasos.laskos@arachni-scanner.com">Tasos Laskos</a> (<a href="http://twitter.com/Zap0tek">@Zap0tek</a>)</td>
    </tr>
    <tr>
        <th>Twitter</th>
        <td><a href="http://twitter.com/ArachniScanner">@ArachniScanner</a></td>
    </tr>
    <tr>
        <th>Copyright</th>
        <td>2010-2017 <a href="http://www.sarosys.com">Sarosys LLC</a></td>
    </tr>
    <tr>
        <th>License</th>
        <td>Arachni Public Source License v1.0 - (see LICENSE file)</td>
    </tr>
</table>

![Arachni logo](http://www.arachni-scanner.com/large-logo.png)

## Synopsis

Arachni is a feature-full, modular, high-performance Ruby framework aimed towards
helping penetration testers and administrators evaluate the security of web applications.

It is smart, it trains itself by monitoring and learning from the web application's
behavior during the scan process and is able to perform meta-analysis using a number of
factors in order to correctly assess the trustworthiness of results and intelligently
identify (or avoid) false-positives.

Unlike other scanners, it takes into account the dynamic nature of web applications,
can detect changes caused while travelling through the paths of a web application’s
cyclomatic complexity and is able to adjust itself accordingly. This way, attack/input
vectors that would otherwise be undetectable by non-humans can be handled seamlessly.

Moreover, due to its integrated browser environment, it can also audit and inspect
client-side code, as well as support highly complicated web applications which make
heavy use of technologies such as JavaScript, HTML5, DOM manipulation and AJAX.

Finally, it is versatile enough to cover a great deal of use cases, ranging from
a simple command line scanner utility, to a global high performance grid of
scanners, to a Ruby library allowing for scripted audits, to a multi-user
multi-scan web collaboration platform.

**Note**: Despite the fact that Arachni is mostly targeted towards web application
security, it can easily be used for general purpose scraping, data-mining, etc.
with the addition of custom components.

### Arachni offers:

#### A stable, efficient, high-performance framework

`Check`, `report` and `plugin` developers are allowed to easily and quickly create and
deploy their components with the minimum amount of restrictions imposed upon them,
while provided with the necessary infrastructure to accomplish their goals.

Furthermore, they are encouraged to take full advantage of the Ruby language under
a unified framework that will increase their productivity without stifling them
or complicating their tasks.

Moreover, that same framework can be utilized as any other Ruby library and lead
to the development of brand new scanners or help you create highly customized
scan/audit scenarios and/or scripted scans.

#### Simplicity

Although some parts of the Framework are fairly complex you will never have to deal them directly.
From a user’s or a component developer’s point of view everything appears simple
and straight-forward all the while providing power, performance and flexibility.

From the simple command-line utility scanner to the intuitive and user-friendly
Web interface and collaboration platform, Arachni follows the principle of least
surprise and provides you with plenty of feedback and guidance.

#### In simple terms

Arachni is designed to automatically detect security issues in web applications.
All it expects is the URL of the target website and after a while it will present
you with its findings.

## Features

### General

 - Cookie-jar/cookie-string support.
 - Custom header support.
 - SSL support with fine-grained options.
 - User Agent spoofing.
 - Proxy support for SOCKS4, SOCKS4A, SOCKS5, HTTP/1.1 and HTTP/1.0.
 - Proxy authentication.
 - Site authentication (SSL-based, form-based, Cookie-Jar, Basic-Digest, NTLMv1, Kerberos and others).
 - Automatic log-out detection and re-login during the scan (when the initial
    login was performed via the `autologin`, `login_script` or `proxy` plugins).
 - Custom 404 page detection.
 - UI abstraction:
    - [Command-line Interface](https://github.com/Arachni/arachni/wiki/Executables).
    - [Web User Interface](https://github.com/Arachni/arachni-ui-web).
 - Pause/resume functionality.
 - Hibernation support -- Suspend to and restore from disk.
 - High performance asynchronous HTTP requests.
    - With adjustable concurrency.
    - With the ability to auto-detect server health and adjust its concurrency
        automatically.
 - Support for custom default input values, using pairs of patterns (to be matched
    against input names) and values to be used to fill in matching inputs.

### Integrated browser environment

Arachni includes an integrated, real browser environment in order to provide
sufficient coverage to modern web applications which make use of technologies
such as HTML5, JavaScript, DOM manipulation, AJAX, etc.

In addition to the monitoring of the vanilla DOM and JavaScript environments,
Arachni's browsers also hook into popular frameworks to make the logged data
easier to digest:

- [JQuery](http://jquery.com/)
- [AngularJS](https://angularjs.org/)
- More to come...

In essence, this turns Arachni into a DOM and JavaScript debugger, allowing it to
monitor DOM events and JavaScript data and execution flows. As a result, not only
can the system trigger and identify DOM-based issues, but it will accompany them
with a great deal of information regarding the state of the page at the time.

Relevant information include:

 - Page DOM, as HTML code.
     - With a list of DOM transitions required to restore the state of the
         page to the one at the time it was logged.
 - Original DOM (i.e. prior to the action that caused the page to be logged),
     as HTML code.
     - With a list of DOM transitions.
 - Data-flow sinks -- Each sink is a JS method which received a tainted argument.
     - Parent object of the method (ex.: `DOMWindow`).
     - Method signature (ex.: `decodeURIComponent()`).
     - Arguments list.
         - With the identified taint located recursively in the included objects.
     - Method source code.
     - JS stacktrace.
 - Execution flow sinks -- Each sink is a successfully executed JS payload,
     as injected by the security checks.
     - Includes a JS stacktrace.
 - JavaScript stack-traces include:
     - Method names.
     - Method locations.
     - Method source codes.
     - Argument lists.

In essence, you have access to roughly the same information that your favorite
debugger (for example, FireBug) would provide, as if you had set a breakpoint to
take place at the right time for identifying an issue.

#### Browser-cluster

The browser-cluster is what coordinates the browser analysis of resources and
allows the system to perform operations which would normally be quite time
consuming in a high-performance fashion.

Configuration options include:

 - Adjustable pool-size, i.e. the amount of browser workers to utilize.
 - Timeout for each job.
 - Worker TTL counted in jobs -- Workers which exceed the TTL have their browser
     process respawned.
 - Ability to disable loading images.
 - Adjustable screen width and height.
     - Can be used to analyze responsive and mobile applications.
 - Ability to wait until certain elements appear in the page.
 - Configurable local storage data.

### Coverage

The system can provide great coverage to modern web applications due to its
integrated browser environment. This allows it to interact with complex applications
that make heavy use of client-side code (like JavaScript) just like a human would.

In addition to that, it also knows about which browser state changes the application
has been programmed to handle and is able to trigger them programatically in
order to provide coverage for a full set of possible scenarios.

By inspecting all possible pages and their states (when using client-side code)
Arachni is able to extract and audit the following elements and their inputs:

 - Forms
    - Along with ones that require interaction via a real browser due to DOM events.
 - User-interface Forms
    - Input and button groups which don't belong to an HTML `<form>` element but
        are instead associated via JS code.
 - User-interface Inputs
    - Orphan `<input>` elements with associated DOM events.
 - Links
    - Along with ones that have client-side parameters in their fragment, i.e.:
        `http://example.com/#/?param=val&param2=val2`
    - With support for rewrite rules.
 - LinkTemplates -- Allowing for extraction of arbitrary inputs from generic paths,
    based on user-supplied templates -- useful when rewrite rules are not available.
    - Along with ones that have client-side parameters in their URL fragments, i.e.:
            `http://example.com/#/param/val/param2/val2`
 - Cookies
 - Headers
 - Generic client-side elements which have associated DOM events.
 - AJAX-request parameters.
 - JSON request data.
 - XML request data.

### Open [distributed architecture](https://github.com/Arachni/arachni/wiki/Distributed-components)

Arachni is designed to fit into your workflow and easily integrate with your
existing infrastructure.

Depending on the level of control you require over the process, you can either
choose the REST service or the custom RPC protocol.

Both approaches allow you to:

- Remotely monitor and manage scans.
- Perform multiple scans at the same time -- Each scan is compartmentalized to
    its own OS process to take advantage of:
    - Multi-core/SMP architectures.
    - OS-level scheduling/restrictions.
    - Sandboxed failure propagation.
- Communicate over a secure channel.

#### [REST API](https://github.com/Arachni/arachni/wiki/REST-API)

- Very simple and straightforward API.
- Easy interoperability with non-Ruby systems.
    - Operates over HTTP.
    - Uses JSON to format messages.
- Stateful scan monitoring.
    - Unique sessions automatically only receive updates when polling for progress,
        rather than full data.

#### [RPC API](https://github.com/Arachni/arachni/wiki/RPC-API)

- High-performance/low-bandwidth [communication protocol](https://github.com/Arachni/arachni-rpc).
    - `MessagePack` serialization for performance, efficiency and ease of
        integration with 3rd party systems.
- Grid:
    - Self-healing.
    - Scale up/down by hot-plugging/hot-unplugging nodes.
        - Can scale up infinitely by adding nodes to increase scan capacity.
    - _(Always-on)_ Load-balancing -- All Instances are automatically provided
        by the least burdened Grid member.
        - With optional per-scan opt-out/override.
    - _(Optional)_ High-Performance mode -- Combines the resources of
        multiple nodes to perform multi-Instance scans.
        - Enabled on a per-scan basis.

### Scope configuration

 - Filters for redundant pages like galleries, catalogs, etc. based on regular
    expressions and counters.
    - Can optionally detect and ignore redundant pages automatically.
 - URL exclusion filters using regular expressions.
 - Page exclusion filters based on content, using regular expressions.
 - URL inclusion filters using regular expressions.
 - Can be forced to only follow HTTPS paths and not downgrade to HTTP.
 - Can optionally follow subdomains.
 - Adjustable page count limit.
 - Adjustable redirect limit.
 - Adjustable directory depth limit.
 - Adjustable DOM depth limit.
 - Adjustment using URL-rewrite rules.
 - Can read paths from multiple user supplied files (to both restrict and extend
    the scope).

### Audit

 - Can audit:
    - Forms
        - Can automatically refresh nonce tokens.
        - Can submit them via the integrated browser environment.
     - User-interface Forms
        - Input and button groups which don't belong to an HTML `<form>` element
            but are instead associated via JS code.
    - User-interface Inputs
        - Orphan `<input>` elements with associated DOM events.
    - Links
        - Can load them via the integrated browser environment.
    - LinkTemplates
        - Can load them via the integrated browser environment.
    - Cookies
        - Can load them via the integrated browser environment.
    - Headers
    - Generic client-side DOM elements.
    - JSON request data.
    - XML request data.
 - Can ignore binary/non-text pages.
 - Can audit elements using both `GET` and `POST` HTTP methods.
 - Can inject both raw and HTTP encoded payloads.
 - Can submit all links and forms of the page along with the cookie
    permutations to provide extensive cookie-audit coverage.
 - Can exclude specific input vectors by name.
 - Can include specific input vectors by name.

### Components

Arachni is a highly modular system, employing several components of distinct
types to perform its duties.

In addition to enabling or disabling the bundled components so as to adjust the
system's behavior and features as needed, functionality can be extended via the
addition of user-created components to suit almost every need.

#### Platform fingerprinters

In order to make efficient use of the available bandwidth, Arachni performs
rudimentary platform fingerprinting and tailors the audit process to the server-side
deployed technologies by only using applicable payloads.

Currently, the following platforms can be identified:

- Operating systems
    - BSD
    - Linux
    - Unix
    - Windows
    - Solaris
- Web servers
    - Apache
    - IIS
    - Nginx
    - Tomcat
    - Jetty
    - Gunicorn
- Programming languages
    - PHP
    - ASP
    - ASPX
    - Java
    - Python
    - Ruby
- Frameworks
    - Rack
    - CakePHP
    - Rails
    - Django
    - ASP.NET MVC
    - JSF
    - CherryPy
    - Nette
    - Symfony

The user also has the option of specifying extra platforms (like a DB server)
in order to help the system be as efficient as possible. Alternatively, fingerprinting
can be disabled altogether.

Finally, Arachni will always err on the side of caution and send all available
payloads when it fails to identify specific platforms.

#### Checks

_Checks_ are system components which perform security checks and log issues.

##### Active

Active checks engage the web application via its inputs.

- SQL injection (`sql_injection`) -- Error based detection.
    - Oracle
    - InterBase
    - PostgreSQL
    - MySQL
    - MSSQL
    - EMC
    - SQLite
    - DB2
    - Informix
    - Firebird
    - SaP Max DB
    - Sybase
    - Frontbase
    - Ingres
    - HSQLDB
    - MS Access
- Blind SQL injection using differential analysis (`sql_injection_differential`).
- Blind SQL injection using timing attacks (`sql_injection_timing`).
    - MySQL
    - PostgreSQL
    - MSSQL
- NoSQL injection (`no_sql_injection`) -- Error based vulnerability detection.
    - MongoDB
- Blind NoSQL injection using differential analysis (`no_sql_injection_differential`).
- CSRF detection (`csrf`).
- Code injection (`code_injection`).
    - PHP
    - Ruby
    - Python
    - Java
    - ASP
- Blind code injection using timing attacks (`code_injection_timing`).
    - PHP
    - Ruby
    - Python
    - Java
    - ASP
- LDAP injection (`ldap_injection`).
- Path traversal (`path_traversal`).
    - *nix
    - Windows
    - Java
- File inclusion (`file_inclusion`).
    - *nix
    - Windows
    - Java
    - PHP
    - Perl
- Response splitting (`response_splitting`).
- OS command injection (`os_cmd_injection`).
    - *nix
    - *BSD
    - IBM AIX
    - Windows
- Blind OS command injection using timing attacks (`os_cmd_injection_timing`).
    - Linux
    - *BSD
    - Solaris
    - Windows
- Remote file inclusion (`rfi`).
- Unvalidated redirects (`unvalidated_redirect`).
- Unvalidated DOM redirects (`unvalidated_redirect_dom`).
- XPath injection (`xpath_injection`).
    - Generic
    - PHP
    - Java
    - dotNET
    - libXML2
- XSS (`xss`).
- Path XSS (`xss_path`).
- XSS in event attributes of HTML elements (`xss_event`).
- XSS in HTML tags (`xss_tag`).
- XSS in script context (`xss_script_context`).
- DOM XSS (`xss_dom`).
- DOM XSS script context (`xss_dom_script_context`).
- Source code disclosure (`source_code_disclosure`)
- XML External Entity (`xxe`).
    - Linux
    - *BSD
    - Solaris
    - Windows

##### Passive

Passive checks look for the existence of files, folders and signatures.

- Allowed HTTP methods (`allowed_methods`).
- Back-up files (`backup_files`).
- Backup directories (`backup_directories`)
- Common administration interfaces (`common_admin_interfaces`).
- Common directories (`common_directories`).
- Common files (`common_files`).
- HTTP PUT (`http_put`).
- Insufficient Transport Layer Protection for password forms (`unencrypted_password_form`).
- WebDAV detection (`webdav`).
- HTTP TRACE detection (`xst`).
- Credit Card number disclosure (`credit_card`).
- CVS/SVN user disclosure (`cvs_svn_users`).
- Private IP address disclosure (`private_ip`).
- Common backdoors (`backdoors`).
- .htaccess LIMIT misconfiguration (`htaccess_limit`).
- Interesting responses (`interesting_responses`).
- HTML object grepper (`html_objects`).
- E-mail address disclosure (`emails`).
- US Social Security Number disclosure (`ssn`).
- Forceful directory listing (`directory_listing`).
- Mixed Resource/Scripting (`mixed_resource`).
- Insecure cookies (`insecure_cookies`).
- HttpOnly cookies (`http_only_cookies`).
- Auto-complete for password form fields (`password_autocomplete`).
- Origin Spoof Access Restriction Bypass (`origin_spoof_access_restriction_bypass`)
- Form-based upload (`form_upload`)
- localstart.asp (`localstart_asp`)
- Cookie set for parent domain (`cookie_set_for_parent_domain`)
- Missing `Strict-Transport-Security` headers for HTTPS sites (`hsts`).
- Missing `X-Frame-Options` headers (`x_frame_options`).
- Insecure CORS policy (`insecure_cors_policy`).
- Insecure cross-domain policy (allow-access-from) (`insecure_cross_domain_policy_access`)
- Insecure cross-domain policy (allow-http-request-headers-from) (`insecure_cross_domain_policy_headers`)
- Insecure client-access policy (`insecure_client_access_policy`)

#### Reporters

- Standard output
- [HTML](http://www.arachni-scanner.com/reports/report.html/)
    ([zip](http://www.arachni-scanner.com/reports/report.html.zip)) (`html`).
- [XML](http://www.arachni-scanner.com/reports/report.xml) (`xml`).
- [Text](http://www.arachni-scanner.com/reports/report.txt) (`text`).
- [JSON](http://www.arachni-scanner.com/reports/report.json) (`json`)
- [Marshal](http://www.arachni-scanner.com/reports/report.marshal) (`marshal`)
- [YAML](http://www.arachni-scanner.com/reports/report.yml) (`yaml`)
- [AFR](http://www.arachni-scanner.com/reports/report.afr) (`afr`)
    - The default Arachni Framework Report format.

#### Plugins

Plugins add extra functionality to the system in a modular fashion, this way the
core remains lean and makes it easy for anyone to add arbitrary functionality.

- Passive Proxy  (`proxy`) -- Analyzes requests and responses between the web app and
    the browser assisting in AJAX audits, logging-in and/or restricting the scope of the audit.
- Form based login (`autologin`).
- Script based login (`login_script`).
- Dictionary attacker for HTTP Auth (`http_dicattack`).
- Dictionary attacker for form based authentication (`form_dicattack`).
- Cookie collector (`cookie_collector`) -- Keeps track of cookies while establishing a timeline of changes.
- WAF (Web Application Firewall) Detector (`waf_detector`) -- Establishes a baseline of
    normal behavior and uses rDiff analysis to determine if malicious inputs cause any behavioral changes.
- BeepNotify (`beep_notify`) -- Beeps when the scan finishes.
- EmailNotify (`email_notify`) -- Sends a notification (and optionally a report) over SMTP at
    the end of the scan.
- VectorFeed (`vector_feed`) -- Reads in vector data from which it creates elements to be
    audited. Can be used to perform extremely specialized/narrow audits on a per vector/element basis.
    Useful for unit-testing or a gazillion other things.
- Script (`script`) -- Loads and runs an external Ruby script under the scope of a plugin,
    used for debugging and general hackery.
- Uncommon headers (`uncommon_headers`) -- Logs uncommon headers.
- Content-types (`content_types`) -- Logs content-types of server responses aiding in the
    identification of interesting (possibly leaked) files.
- Vector collector (`vector_collector`) -- Collects information about all seen input vectors
    which are within the scan scope.
- Headers collector (`headers_collector`) -- Collects response headers based on specified criteria.
- Exec (`exec`) -- Calls external executables at different scan stages.
- Metrics (`metrics`) -- Captures metrics about multiple aspects of the scan and the web application.
- Restrict to DOM state (`restrict_to_dom_state`) -- Restricts the audit to a single page's DOM
    state, based on a URL fragment.
- Webhook notify (`webhook_notify`) -- Sends a webhook payload over HTTP at the end of the scan.
- Rate limiter (`rate_limiter`) -- Rate limits HTTP requests.
- Page dump (`page_dump`) -- Dumps page data to disk as YAML.

##### Defaults

Default plugins will run for every scan and are placed under `/plugins/defaults/`.

- AutoThrottle (`autothrottle`) -- Dynamically adjusts HTTP throughput during the scan for
    maximum bandwidth utilization.
- Healthmap (`healthmap`) -- Generates sitemap showing the health of each crawled/audited URL

###### Meta

Plugins under `/plugins/defaults/meta/` perform analysis on the scan results
to determine trustworthiness or just add context information or general insights.

- TimingAttacks (`timing_attacks`) -- Provides a notice for issues uncovered by timing attacks
    when the affected audited pages returned unusually high response times to begin with.
    It also points out the danger of DoS attacks against pages that perform heavy-duty processing.
- Discovery (`discovery`) -- Performs anomaly detection on issues logged by discovery
    checks and warns of the possibility of false positives where applicable.
- Uniformity (`uniformity`) -- Reports inputs that are uniformly vulnerable across a number
    of pages hinting to the lack of a central point of input sanitization.

### Trainer subsystem

The Trainer is what enables Arachni to learn from the scan it performs and
incorporate that knowledge, on the fly, for the duration of the audit.

Checks have the ability to individually force the Framework to learn from the
HTTP responses they are going to induce.

However, this is usually not required since Arachni is aware of which requests
are more likely to uncover new elements or attack vectors and will adapt itself
accordingly.

Still, this can be an invaluable asset to Fuzzer checks.

## [Installation](https://github.com/Arachni/arachni/wiki/Installation)

## [Usage](https://github.com/Arachni/arachni/wiki/User-guide)

## Running the specs

You can run `rake spec` to run **all** specs or you can run them selectively using the following:

    rake spec:core            # for the core libraries
    rake spec:checks          # for the checks
    rake spec:plugins         # for the plugins
    rake spec:reports         # for the reports
    rake spec:path_extractors # for the path extractors

**Please be warned**, the core specs will require a beast of a machine due to the
necessity to test the Grid/multi-Instance features of the system.

**Note**: _The check specs will take many hours to complete due to the timing-attack tests._

## Bug reports/Feature requests

Submit bugs using [GitHub Issues](http://github.com/Arachni/arachni/issues) and
get support via the [Support Portal](http://support.arachni-scanner.com).

## Contributing

(Before starting any work, please read the [instructions](https://github.com/Arachni/arachni/tree/experimental#source)
for working with the source code.)

We're happy to accept help from fellow code-monkeys and these are the steps you
need to follow in order to contribute code:

* Fork the project.
* Start a feature branch based on the [experimental](https://github.com/Arachni/arachni/tree/experimental)
    branch (`git checkout -b <feature-name> experimental`).
* Add specs for your code.
* Run the spec suite to make sure you didn't break anything (`rake spec:core`
    for the core libs or `rake spec` for everything).
* Commit and push your changes.
* Issue a pull request and wait for your code to be reviewed.

## License

Arachni Public Source License v1.0 -- please see the _LICENSE_ file for more information.
