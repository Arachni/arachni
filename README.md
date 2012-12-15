# Arachni - Web Application Security Scanner Framework

<table>
    <tr>
        <th>Version</th>
        <td>v0.4.1.3</td>
    </tr>
    <tr>
        <th>Homepage</th>
        <td><a href="http://arachni-scanner.com">http://arachni-scanner.com</a></td>
    </tr>
    <tr>
        <th>Blog</th>
        <td><a href="http://arachni-scanner.com/blog">http://arachni-scanner.com/blog</a></td>
    <tr>
        <th>Github</th>
        <td><a href="http://github.com/Arachni/arachni">http://github.com/Arachni/arachni</a></td>
     <tr/>
    <tr>
        <th>Documentation</th>
        <td><a href="http://arachni-scanner.com/wiki">http://arachni-scanner.com/wiki</a></td>
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
        <td>2010-2012 Tasos Laskos</td>
    </tr>
    <tr>
        <th>License</th>
        <td><a href="file.LICENSE.html">Apache License Version 2.0</a></td>
    </tr>
</table>

![Arachni logo](http://arachni.github.com/arachni/logo.png)

## Synopsis

Arachni is a feature-full, modular, high-performance Ruby framework aimed towards helping
penetration testers and administrators evaluate the security of web applications.

Arachni is smart, it trains itself by learning from the HTTP responses it receives
during the audit process and is able to perform meta-analysis using a number of
factors in order to correctly assess the trustworthiness of results and intelligently
identify false-positives.

Unlike other scanners, it takes into account the dynamic nature of web applications,
can detect changes caused while travelling through the paths of a web application's
cyclomatic complexity and is able to adjust itself accordingly.

This way attack/input vectors that would otherwise be undetectable by non-humans
are seamlessly handled by Arachni.

Moreover, Arachni yields great performance due to its asynchronous HTTP model
 -- especially when combined with a High Performance Grid setup which allows you
to combine the resources of multiple nodes for lightning fast scans.

Thus, you'll only be limited by the responsiveness of the server under audit.

Finally, it is versatile enough to cover a great deal of use cases, ranging from a
simple command line scanner utility, to a global high performance grid of scanners,
to a Ruby library allowing for scripted audits.

**Note**: _Despite the fact that Arachni is mostly targeted towards web
application security, it can easily be used for general purpose scraping,
data-mining, etc with the addition of custom modules._


### Arachni offers:

#### A stable, efficient, high-performance framework

Module, report and plugin writers are allowed to easily and quickly create and
deploy their components with the minimum amount of restrictions imposed upon
them, while provided with the necessary infrastructure to accomplish their goals.

Furthermore, they are encouraged to take full advantage of the Ruby language under
a unified framework that will increase their productivity without stifling them
or complicating their tasks.

#### Simplicity

Although some parts of the Framework are fairly complex you will never have
to deal them directly.
From a user's or a component developer's point of view everything appears simple
and straight-forward all the while providing power, performance and flexibility.

## Feature List

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
 - Highlighted command line output.
 - UI abstraction:
    - Command line UI
    - Web UI (Utilizing the Client - Dispatcher RPC infrastructure)
 - Pause/resume functionality.
 - High performance asynchronous HTTP requests.
    - With adjustable concurrency.
 - Open [RPC](https://github.com/Arachni/arachni/wiki/RPC-API) Client/Dispatcher Infrastructure
    - [Distributed deployment](https://github.com/Arachni/arachni/wiki/Distributed-components)
    - Multiple clients
    - Parallel scans
    - SSL encryption (with peer authentication)
    - Remote monitoring
    - Support for [High Performance Grid](https://github.com/Arachni/arachni/wiki/HPG)
        configuration, combining the resources of multiple nodes to perform faster scans.

### Crawler

 - Filters for redundant pages like galleries, catalogs, etc based on regular
    expressions and counters.
    - Can optionally detect and ignore redundant pages automatically.
 - URL exclusion filter based on regular expressions.
 - URL inclusion filter based on regular expressions.
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
 - Can optionally audit forms and links using both ```GET``` and ```POST``` HTTP methods.
 - Can optionally submit all links and forms of the page along with the cookie
    permutations to provide extensive cookie-audit coverage.
 - Can exclude specific input vectors by name.

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
    - For taint analysis, timing attacks, differential analysis, server-side file/directory detection and more.
    - Writing RFI, SQL injection, XSS etc modules is a matter of minutes, if not seconds.
 - Currently available modules:
    - Audit:
        - SQL injection (Oracle, ColdFusion, InterBase, PostgreSQL, MySQL, MSSQL, EMC, SQLite, DB2, Informix)
        - Blind SQL injection using rDiff analysis
        - Blind SQL injection using timing attacks (MySQL, PostgreSQL, MSSQL
        - CSRF detection
        - Code injection (PHP, Ruby, Python, JSP, ASP.NET)
        - Blind code injection using timing attacks (PHP, Ruby, Python, JSP, ASP.NET)
        - LDAP injection
        - Path traversal (*nix, Windows)
        - Response splitting
        - OS command injection (*nix, Windows)
        - Blind OS command injection using timing attacks (*nix, Windows)
        - Remote file inclusion
        - Unvalidated redirects
        - XPath injection (Generic, PHP, Java, dotNET, libXML2)
        - Path XSS
        - URI XSS
        - XSS
        - XSS in event attributes of HTML elements
        - XSS in HTML tags
        - XSS in HTML 'script' tags
    - Recon:
        - Allowed HTTP methods
        - Back-up files
        - Common directories
        - Common files
        - HTTP PUT
        - Insufficient Transport Layer Protection for password forms
        - WebDAV detection
        - HTTP TRACE detection
        - Credit Card number disclosure
        - CVS/SVN user disclosure
        - Private IP address disclosure
        - Common backdoors
        - .htaccess LIMIT misconfiguration
        - Interesting responses
        - HTML object grepper
        - E-mail address disclosure
        - US Social Security Number disclosure
        - Forceful directory listing
        - Mixed Resource/Scripting
        - Insecure cookies
        - HttpOnly cookies

### Report Management

 - Modular design.
 - Currently available reports:
    - Standard output
    - HTML (Cheers to [Christos Chiotis](mailto:chris@survivetheinternet.com)
        for designing the new HTML report template.)
    - XML
    - TXT
    - AFR -- The default Arachni Framework Report format.
    - JSON
    - Marshal
    - YAML
    - Metareport -- Providing Metasploit integration to allow for [automated and
        assisted exploitation](http://arachni.github.com/arachni/file.EXPLOITATION.html).

### Plug-in Management

 - Modular design
 - Plug-ins are framework demi-gods, they have direct access to the framework instance.
 - Can be used to add any functionality to Arachni.
 - Currently available plugins:
    - ReScan -- It uses the AFR report of a previous scan to extract the sitemap
        in order to avoid a redundant crawl.
    - Passive Proxy -- Analyzes requests and responses between the web app and
        the browser assisting in AJAX audits, logging-in and/or restricting the scope of the audit
    - Form based AutoLogin
    - Dictionary attacker for HTTP Auth
    - Dictionary attacker for form based authentication
    - Profiler -- Performs taint analysis (with benign inputs) and response time analysis
    - Cookie collector -- Keeps track of cookies while establishing a timeline of changes
    - Healthmap -- Generates sitemap showing the health of each crawled/audited URL
    - Content-types -- Logs content-types of server responses aiding in the
        identification of interesting (possibly leaked) files
    - WAF (Web Application Firewall) Detector -- Establishes a baseline of
        normal behavior and uses rDiff analysis to determine if malicious inputs cause any behavioral changes
    - AutoThrottle -- Dynamically adjusts HTTP throughput during the scan for
        maximum bandwidth utilization
    - TimingAttacks -- Provides a notice for issues uncovered by timing attacks
        when the affected audited pages returned unusually high response times to begin with.</br>
         It also points out the danger of DoS attacks against pages that perform heavy-duty processing.
    - Uniformity -- Reports inputs that are uniformly vulnerable across a number
        of pages hinting to the lack of a central point of input sanitization.
    - Discovery -- Performs anomaly detection on issues logged by discovery
        modules and warns of the possibility of false positives where applicable.
    - BeepNotify -- Beeps when the scan finishes.
    - LibNotify -- Uses the libnotify library to send notifications for each
        discovered issue and a summary at the end of the scan.
    - EmailNotify -- Sends a notification (and optionally a report) over SMTP at
        the end of the scan.
    - Manual verification -- Flags issues that require manual verification as
        untrusted in order to reduce the signal-to-noise ratio.
    - Resolver -- Resolves vulnerable hostnames to IP addresses.
    - VectorFeed -- Reads in vector data from which it creates elements to be
        audited. Can be used to perform extremely specialized/narrow audits on a per vector/element basis.
        Useful for unit-testing or a gazillion other things.
    - Script -- Loads and runs an external Ruby script under the scope of a plugin,
        used for debugging and general hackery.

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

## Configuration of <em>extras</em>

The <em>extras</em> directory holds components that are considered too specialised,
dangerous or in some way unsuitable for utilising without explicit user interaction.

This directory was mainly added to distribute modules which can be helpful but
should not be put in the default <em>modules</em> directory to prevent them from
being automatically loaded.

Should you want to use these extra components simply move them from the
<em>extras</em> folder to their appropriate system directories.

## Running the specs

You can run ```rake spec``` to run **all** specs or you can run them selectively using the following:
```
rake spec:core            # for the core libraries
rake spec:modules         # for the modules
rake spec:plugins         # for the plugins
rake spec:reports         # for the reports
rake spec:path_extractors # for the path extractors
```

**Note**: _The module specs will take about 90 minutes due to the ones which perform timing attacks._

## Contributing

We're happy to accept help from fellow code-monkeys and these are the steps you
need to follow in order to contribute code:

* [Fork the project](https://github.com/Arachni/arachni/fork_select)
* Develop on the experimental branch (```git checkout experimental```)
* Add specs for your code
* Run the spec suite to make sure you didn't break anything (```rake spec:core```
    for the core libs or ```rake spec``` for everything)
* Issue a pull request and wait for your code to be reviewed

That's all. :)

## Bug reports/Feature requests

Submit bugs using [GitHub Issues](http://github.com/Arachni/arachni/issues).<br/>
Get support via the [Support Portal](http://support.arachni-scanner.com).


## License

Arachni is licensed under the Apache License Version 2.0.<br/>
See the [LICENSE](file.LICENSE.html) file for more information.


## Disclaimer

Arachni is free software and you are allowed to use it as you see fit.<br/>
However, I can't be held responsible for your actions or for any damage
caused by the use of this software.

![Arachni banner](http://arachni.github.com/arachni/banner.png)
