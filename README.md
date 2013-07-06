# Experimental/unstable branch -- used for development/integration

This branch is where all development takes place, once its code has been tested and
is considered stable, it is then merged into the `master` branch and released.

Do not be confused by the version of this branch, `1.0dev` is a placeholder
which simply means _next release_.

## Nightlies

For self-contained, nightly snapshot packages take a look at:
http://downloads.arachni-scanner.com/nightlies/

## Source

To run from source you first need to setup a
[development environment](https://github.com/Arachni/arachni/wiki/Development-environment).

**After** you've setup a [development environment](https://github.com/Arachni/arachni/wiki/Development-environment),
run the following to checkout the source code of the `experimental` branch and
resolve its dependencies:

    git clone git://github.com/Arachni/arachni.git
    cd arachni
    git checkout experimental
    bundle install # to resolve dev dependencies

Then you can run Arachni using the the executables under `bin/`.<br/>
If you get an error when trying to run Arachni, use `bundle exec` like so:
`bundle exec <executable>`.

# Arachni - Web Application Security Scanner Framework

<table>
    <tr>
        <th>Version</th>
        <td>1.0dev</td>
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
       <td><a href="mailto:tasos.laskos@gmail.com">Tasos Laskos</a> (<a href="http://twitter.com/Zap0tek">@Zap0tek</a>)</td>
    </tr>
    <tr>
        <th>Twitter</th>
        <td><a href="http://twitter.com/ArachniScanner">@ArachniScanner</a></td>
    </tr>
    <tr>
        <th>Copyright</th>
        <td>2010-2013 Tasos Laskos</td>
    </tr>
    <tr>
        <th>License</th>
        <td><a href="file.LICENSE.html">Apache License Version 2.0</a></td>
    </tr>
</table>

![Arachni logo](http://arachni.github.com/arachni/logo.png)

## Synopsis

Arachni is an Open Source, feature-full, modular, high-performance Ruby framework
aimed towards helping penetration testers and administrators evaluate the security
of web applications.

It is smart, it trains itself by learning from the HTTP responses it receives
during the audit process and is able to perform meta-analysis using a number of
factors in order to correctly assess the trustworthiness of results and intelligently
identify false-positives.

Unlike other scanners, it takes into account the dynamic nature of web applications,
can detect changes caused while travelling through the paths of a web application’s
cyclomatic complexity and is able to adjust itself accordingly. This way attack/input
vectors that would otherwise be undetectable by non-humans are seamlessly handled by Arachni.

Moreover, Arachni yields great performance due to its asynchronous HTTP model
(courtesy of Typhoeus) — especially when combined with a High Performance Grid
setup which allows you to combine the resources of multiple nodes for lightning
fast scans. Thus, you’ll only be limited by the responsiveness of the server under audit.

Finally, it is versatile enough to cover a great deal of use cases, ranging from
a simple command line scanner utility, to a global high performance grid of
scanners, to a Ruby library allowing for scripted audits, to a multi-user
multi-scan web collaboration platform.

**Note**: Despite the fact that Arachni is mostly targeted towards web application
security, it can easily be used for  general purpose scraping, data-mining, etc
with the addition of custom modules.

### Arachni offers:

#### A stable, efficient, high-performance framework

Module, report and plugin writers are allowed to easily and quickly create and
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
Web interface and collaboration platform, Arachni follows the principle of lease
surprise and provides you with plenty of feedback and guidance.

#### In simple terms

Arachni is designed to automatically detect security issues in web applications.
All it expects is the URL of the target website and after a while it will present
you with its findings.

## Features

### General

 - Cookie-jar/cookie-string support.
 - Custom header support.
 - SSL support.
 - User Agent spoofing.
 - Proxy support for SOCKS4, SOCKS4A, SOCKS5, HTTP/1.1 and HTTP/1.0.
 - Proxy authentication.
 - Site authentication (Automated form-based, Cookie-Jar, Basic-Digest, NTLM and others).
 - Automatic log-out detection and re-login during the audit (when the initial
    login was performed via the AutoLogin plugin).
 - Custom 404 page detection.
 - UI abstraction:
    - [Command-line Interface](https://github.com/Arachni/arachni/wiki/Executables).
    - [Web User Interface](https://github.com/Arachni/arachni-ui-web).
 - Pause/resume functionality.
 - High performance asynchronous HTTP requests.
    - With adjustable concurrency.

### Open [distributed architecture](https://github.com/Arachni/arachni/wiki/Distributed-components)

- High-performance/low-bandwidth [communication protocol](https://github.com/Arachni/arachni-rpc-em).
    - `Marshal` serialization for performance and efficiency.
        - Automatically falls back to `YAML` for ease of integration with 3rd party systems.
    - TCP/IP for general network communications.
    - UNIX domain sockets for multi-Instance IPC.
- Remote monitoring and management of Dispatchers and Instances.
- Parallel scans -- Each scan is compartmentalized to its own OS process to take
    advantage of:
    - Multi-core/SMP architectures.
    - OS-level scheduling/restrictions.
    - Sandboxed failure propagation.
- Multi-Instance scans for parallelization of _individual scans_ using multiple
    Instances to:
    - Take advantage of multi-core/SMP architectures.
    - Greatly diminish scan-times.
- Dispatcher Grids supporting:
    - _(Optional)_ High-Performance mode -- Combines the resources of
        multiple nodes to perform multi-Instance scans.
        - Enabled on a per-scan basis.
    - _(Always-on)_ Load-balancing -- All Instances are automatically provided
        by the least burdened Grid member.
        - With optional per-scan opt-out/override.
- SSL encryption (with optional peer authentication).

### Crawler

 - Filters for redundant pages like galleries, catalogs, etc based on regular
    expressions and counters.
    - Can optionally detect and ignore redundant pages automatically.
 - URL exclusion filter using regular expressions.
 - Page exclusion filter based on content, using regular expressions.
 - URL inclusion filter using regular expressions.
 - Can be forced to only follow HTTPS paths and not downgrade to HTTP.
 - Can optionally follow subdomains.
 - Adjustable link count limit.
 - Adjustable redirect limit.
 - Adjustable depth limit.
 - Modular path extraction via "Path Extractor" components.
 - Can read paths from multiple user supplied files (to both restrict and extend
    the scope of the crawl).

### Auditor

 - Can audit:
    - Forms
        - Can refresh nonce tokens.
    - Links
    - Cookies
    - Headers
 - Can ignore binary/non-text pages.
 - Can optionally audit forms and links using both `GET` and `POST` HTTP methods.
 - Can optionally submit all links and forms of the page along with the cookie
    permutations to provide extensive cookie-audit coverage.
 - Can exclude specific input vectors by name.

### Platform fingerprinter

In order to make efficient use of the available bandwidth, Arachni performs some
basic platform fingerprinting and tailors the audit process to the server-side
deployed platforms by only injecting applicable payloads.

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
- Programming languages
    - PHP
    - ASP
    - ASPX
    - JSP
    - Python
    - Ruby
- Frameworks
    - Rack

The user also has the option of specifying extra platforms (like a DB server)
in order to help the system be as efficient as possible. Alternatively, fingerprinting
can be disabled altogether.

Finally, Arachni will always err on the side of caution and send all available
payloads when it fails to identify specific platforms.

### HTML Parser

Can extract and analyze:

 - Forms
 - Links
 - Cookies
 - Headers

###  Module Management

 - Very simple and easy to use module API providing access to multiple levels of complexity.
 - Helper audit methods:
    - For form, link, cookie and header auditing.
    - A wide range of injection strings/input combinations.
    - For taint analysis, timing attacks, differential analysis, server-side
        file/directory detection and more.
    - Writing RFI, SQL injection, XSS etc modules is a matter of minutes, if not seconds.

#### Available modules (security checks)

Modules are system components which perform security checks and log issues.

##### Audit (Active)

Audit modules actively engage the web application via its inputs.

- SQL injection (`sqli`) -- Error based vulnerability detection.
    - Oracle
    - ColdFusion
    - InterBase
    - PostgreSQL
    - MySQL
    - MSSQL
    - EMC
    - SQLite
    - DB2
    - Informix
- Blind SQL injection using rDiff analysis (`sqli_blind_rdiff`).
- Blind SQL injection using timing attacks (`sqli_blind_timing`).
    - MySQL
    - PostgreSQL
    - MSSQL
- CSRF detection (`csrf`).
- Code injection (`code_injection`).
    - PHP
    - Ruby
    - Python
    - JSP
    - ASP.NET
- Blind code injection using timing attacks (`code_injection_timing`).
    - PHP
    - Ruby
    - Python
    - JSP
    - ASP.NET
- LDAP injection (`ldapi`).
- Path traversal (`path_traversal`).
    - *nix
    - Windows
    - Tomcat
- Response splitting (`response_splitting`).
- OS command injection (`os_cmd_injection`).
    - *nix
    - Windows
- Blind OS command injection using timing attacks (`os_cmd_injection_timing`).
    - Linux
    - *BSD
    - Solaris
    - Windows
- Remote file inclusion (`rfi`).
- Unvalidated redirects (`unvalidated_redirect`).
- XPath injection (`xpath`).
    - Generic
    - PHP
    - Java
    - dotNET
    - libXML2
- XSS (`xss`).
- Path XSS (`xss_path`).
- XSS in event attributes of HTML elements (`xss_event`).
- XSS in HTML tags (`xss_tag`).
- XSS in HTML 'script' tags  (`xss_script_tag`).

##### Recon (Passive)

Recon modules look for the existence of files, folders and signatures.

- Allowed HTTP methods (`allowed_methods`).
- Back-up files (`backup_files`).
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

### Report Management

 - Modular design.

#### Available reports

- Standard output
- HTML (`html`).
- XML (`xml`).
- TXT (`text`).
- AFR (`afr`) -- The default Arachni Framework Report format.
- JSON (`json`)
- Marshal (`marshal`)
- YAML (`yaml`)
- Metareport  (`metareport`) -- Providing Metasploit integration to allow for
    [automated and assisted exploitation](http://arachni.github.com/arachni/file.EXPLOITATION.html).

### Plug-in Management

 - Modular design.
 - Plug-ins are framework demi-gods, they have direct access to the framework instance.
 - Can be used to add abstract functionality to Arachni.

#### Available plugins

Plugins add extra functionality to the system in a modular fashion, this way the
core remains lean and makes it easy for anyone to arbitrary functionality.

- ReScan  (`rescan`)-- It uses the AFR report of a previous scan to extract the sitemap
    in order to avoid a redundant crawl.
- Passive Proxy  (`proxy`) -- Analyzes requests and responses between the web app and
    the browser assisting in AJAX audits, logging-in and/or restricting the scope of the audit.
- Form based AutoLogin (`autologin`).
- Dictionary attacker for HTTP Auth (`http_dicattack`).
- Dictionary attacker for form based authentication (`form_dicattack`).
- Profiler (`profiler`) -- Performs taint analysis (with benign inputs) and response time analysis.
- Cookie collector (`cookie_collector`) -- Keeps track of cookies while establishing a timeline of changes.
- WAF (Web Application Firewall) Detector (`waf_detector`) -- Establishes a baseline of
    normal behavior and uses rDiff analysis to determine if malicious inputs cause any behavioral changes.
- BeepNotify (`beep_notify`) -- Beeps when the scan finishes.
- LibNotify (`libnotify`) -- Uses the libnotify library to send notifications for each
    discovered issue and a summary at the end of the scan.
- EmailNotify (`email_notify`) -- Sends a notification (and optionally a report) over SMTP at
    the end of the scan.
- VectorFeed (`vector_feed`) -- Reads in vector data from which it creates elements to be
    audited. Can be used to perform extremely specialized/narrow audits on a per vector/element basis.
    Useful for unit-testing or a gazillion other things.
- Script (`script`) -- Loads and runs an external Ruby script under the scope of a plugin,
    used for debugging and general hackery.

#### Defaults

Default plugins will run for every scan and are placed under `/plugins/defaults/`.

- AutoThrottle (`autothrottle`) -- Dynamically adjusts HTTP throughput during the scan for
    maximum bandwidth utilization.
- Content-types (`content_types`) -- Logs content-types of server responses aiding in the
    identification of interesting (possibly leaked) files.
- Healthmap (`healthmap`) -- Generates sitemap showing the health of each crawled/audited URL
- Resolver (`resolver`) -- Resolves vulnerable hostnames to IP addresses.

##### Meta

Plugins under `/plugins/defaults/meta/` perform analysis on the scan results
to determine trustworthiness or just add context information or general insights.

- TimingAttacks (`timing_attacks`) -- Provides a notice for issues uncovered by timing attacks
    when the affected audited pages returned unusually high response times to begin with.
    It also points out the danger of DoS attacks against pages that perform heavy-duty processing.
- Discovery (`discovery`) -- Performs anomaly detection on issues logged by discovery
    modules and warns of the possibility of false positives where applicable.
- Uniformity (`uniformity`) -- Reports inputs that are uniformly vulnerable across a number
    of pages hinting to the lack of a central point of input sanitization.

### Trainer subsystem

The Trainer is what enables Arachni to learn from the scan it performs and
incorporate that knowledge, on the fly, for the duration of the audit.

Modules have the ability to individually force the Framework to learn from the
HTTP responses they are going to induce.

However, this is usually not required since Arachni is aware of which requests
are more likely to uncover new elements or attack vectors and will adapt itself accordingly.

Still, this can be an invaluable asset to Fuzzer modules.

## [Installation](https://github.com/Arachni/arachni/wiki/Installation)

## [Usage](https://github.com/Arachni/arachni/wiki/User-guide)

## Configuration of _extras_

The _extras_ directory holds components that are considered too specialised,
dangerous or in some way unsuitable for utilising without explicit user interaction.

This directory was mainly added to distribute modules which can be helpful but
should not be put in the default _modules_ directory to prevent them from
being automatically loaded.

Should you want to use these extra components simply move them from the
_extras_ folder to their appropriate system directories.

## Running the specs

You can run `rake spec` to run **all** specs or you can run them selectively using the following:

    rake spec:core            # for the core libraries
    rake spec:modules         # for the modules
    rake spec:plugins         # for the plugins
    rake spec:reports         # for the reports
    rake spec:path_extractors # for the path extractors

**Please be warned**, the core specs will require a beast of a machine due to the
necessity to test the Grid/multi-Instance features of the system.

**Note**: _The module specs will take about 90 minutes due to the timing-attack tests._

## Bug reports/Feature requests

Submit bugs using [GitHub Issues](http://github.com/Arachni/arachni/issues) and
get support via the [Support Portal](http://support.arachni-scanner.com).

## Contributing

(Before starting any work, please read the [instructions](https://github.com/Arachni/arachni/tree/experimental#source)
for working with the source code.)

We're happy to accept help from fellow code-monkeys and these are the steps you
need to follow in order to contribute code:

* Fork the project.
* Start a feature branch based on the [experimental](https://github.com/Arachni/arachni-ui-web/tree/experimental)
    branch (`git checkout -b <feature-name> experimental`).
* Add specs for your code.
* Run the spec suite to make sure you didn't break anything (`rake spec:core`
    for the core libs or `rake spec` for everything).
* Commit and push your changes.
* Issue a pull request and wait for your code to be reviewed.

## License

Arachni is licensed under the Apache License Version 2.0.<br/>
See the [LICENSE](file.LICENSE.html) file for more information.

## Disclaimer

This is free software and you are allowed to use it as you see fit.
However, neither the development team nor any of our contributors can held
responsible for your actions or for any damage caused by the use of this software.
