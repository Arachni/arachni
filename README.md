# Arachni - Web Application Security Scanner Framework
**Version**:     0.2.2.1<br/>
**Homepage**:     [http://github.com/zapotek/arachni](http://github.com/zapotek/arachni)<br/>
**News**:     [http://trainofthought.segfault.gr/category/projects/arachni/](http://trainofthought.segfault.gr/category/projects/arachni/)<br/>
**Documentation**:     [http://github.com/Zapotek/arachni/wiki](http://github.com/Zapotek/arachni/wiki)<br/>
**Code Documentation**:     [http://zapotek.github.com/arachni/](http://zapotek.github.com/arachni/)<br/>
**Google Group**: [http://groups.google.com/group/arachni](http://groups.google.com/group/arachni)<br/>
**Author**:       [Tasos](mailto:tasos.laskos@gmail.com) "[Zapotek](mailto:zapotek@segfault.gr)" [Laskos](mailto:tasos.laskos@gmail.com)<br/>
**Twitter**:      [http://twitter.com/Zap0tek](http://twitter.com/Zap0tek)<br/>
**Copyright**:    2010-2011<br/>
**License**:      [GNU General Public License v2](file.LICENSE.html)

![Arachni logo](http://zapotek.github.com/arachni/logo.png)

Kindly sponsored by: [![NopSec](http://zapotek.github.com/arachni/nopsec_logo.png)](http://www.nopsec.com)

Help by donating:
[![Click here to lend your support to: Arachni - Web Application Security Scanner Framework and make a donation at www.pledgie.com!](http://pledgie.com/campaigns/14482.png)](http://www.pledgie.com/campaigns/14482)

## Synopsis

Arachni is a feature-full, modular, high-performance Ruby framework aimed towards helping
penetration testers and administrators evaluate the security of web applications.

Arachni is smart, it trains itself by learning from the HTTP responses it receives during the audit process.<br/>
Unlike other scanners, Arachni takes into account the dynamic nature of web applications and can detect changes caused while travelling<br/>
through the paths of a web application's cyclomatic complexity.<br/>
This way attack/input vectors that would otherwise be undetectable by non-humans are seamlessly handled by Arachni.

Finally, Arachni yields great performance due to its asynchronous HTTP  model (courtesy of [Typhoeus](https://github.com/pauldix/typhoeus)).<br/>
Thus, you'll only be limited by the responsiveness of the server under audit and your available bandwidth.

**Note**: _Despite the fact that Arachni is mostly targeted towards web application security, it can easily be used for general purpose scraping, data-mining, etc with the addition of custom modules._


### Arachni offers:

#### A stable, efficient, high-performance framework

Module, report and plugin writers are allowed to easily and quickly create and deploy their components
with the minimum amount of restrictions imposed upon them, while provided with the necessary infrastructure to accomplish their goals.<br/>
Furthermore, they are encouraged to take full advantage of the Ruby language under a unified framework that will increase their productivity
without stifling them or complicating their tasks.<br/>

#### Simplicity
Although some parts of the Framework are fairly complex you will never have to deal them directly.<br/>
From a user's or a component developer's point of view everything appears simple and straight-forward all the while providing power, performance and flexibility.

## Feature List

### General

 - Cookie-jar support
 - SSL support.
 - User Agent spoofing.
 - Proxy support for SOCKS4, SOCKS4A, SOCKS5, HTTP/1.1 and HTTP/1.0.
 - Proxy authentication.
 - Site authentication (Automated form-based, Cookie-Jar, Basic-Digest, NTLM and others)
 - Highlighted command line output.
 - UI abstraction:
    - Command line UI
    - Web UI (Utilizing the Client - Dispatch-server XMLRPC architecture)
    - XMLRPC Client/Dispatch server
       - Centralised deployment
       - Multiple clients
       - Parallel scans
       - SSL encryption
       - SSL cert based client authentication
       - Remote monitoring
 - Pause/resume functionality.
 - High performance asynchronous HTTP requests.

### Website Crawler

The crawler is provided by a modified version of [Anemone](http://anemone.rubyforge.org/).

 - Filters for redundant pages like galleries, catalogs, etc based on regular expressions and counters.
 - URL exclusion filter based on regular expressions.
 - URL inclusion filter based on regular expressions.
 - Can optionally follow subdomains.
 - Adjustable depth limit.
 - Adjustable link count limit.
 - Adjustable redirect limit.
 - Modular path extraction via "Path Extractor" components.

### HTML Parser

Can extract and analyze:

 - Forms
 - Links
 - Cookies

The analyzer can graciously handle badly written HTML code due to a combination of regular expression analysis and the [Nokogiri](http://nokogiri.org/) HTML parser.

###  Module Management

 - Very simple and easy to use module API providing access to multiple levels of complexity.
 - Helper audit methods:
    - For forms, links and cookies auditing.
    - A wide range of injection strings/input combinations.
    - Writing RFI, SQL injection, XSS etc modules is a matter of minutes if not seconds.
 - Currently available modules:
    - Audit:
        - SQL injection
        - Blind SQL injection using rDiff analysis
        - Blind SQL injection using timing attacks
        - CSRF detection
        - Code injection (PHP, Ruby, Python, JSP, ASP.NET)
        - Blind code injection using timing attacks (PHP, Ruby, Python, JSP, ASP.NET)
        - LDAP injection
        - Path traversal
        - Response splitting
        - OS command injection (*nix, Windows)
        - Blind OS command injection using timing attacks (*nix, Windows)
        - Remote file inclusion
        - Unvalidated redirects
        - XPath injection
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

### Report Management

 - Modular design.
 - Currently available reports:
    - Standard output
    - HTML (Cheers to [Christos Chiotis](mailto:chris@survivetheinternet.com) for designing the new HTML report template.)
    - XML
    - TXT
    - YAML serialization
    - Metareport (providing Metasploit integration to allow for [automated and assisted exploitation](http://zapotek.github.com/arachni/file.EXPLOITATION.html))

### Plug-in Management

 - Modular design
 - Plug-ins are framework demi-gods, they have direct access to the framework instance.
 - Can be used to add any functionality to Arachni.
 - Currently available plugins:
    - Passive Proxy
    - Form based AutoLogin
    - Dictionary attacker for HTTP Auth
    - Dictionary attacker for form based authentication
    - Cookie collector
    - Healthmap -- Generates sitemap showing the health of each crawled/audited URL
    - Content-types -- Logs content-types of server responses aiding in the identification of interesting (possibly leaked) files
    - WAF (Web Application Firewall) Detector
    - MetaModules -- Loads and runs high-level meta-analysis modules pre/mid/post-scan
       - AutoThrottle -- Dynamically adjusts HTTP throughput during the scan for maximum bandwidth utilization
       - TimeoutNotice -- Provides a notice for issues uncovered by timing attacks when the affected audited pages returned unusually high response times to begin with.</br>
            It also points out the danger of DoS attacks against pages that perform heavy-duty processing.
       - Uniformity -- Reports inputs that are uniformly vulnerable across a number of pages hinting to the lack of a central point of input sanitization.

### Trainer subsystem

The Trainer is what enables Arachni to learn from the scan it performs and incorporate that knowledge, on the fly, for the duration of the audit.

Modules have the ability to individually force the Framework to learn from the HTTP responses they are going to induce.<br/>
However, this is usually not required since Arachni is aware of which requests are more likely to uncover new elements or attack vectors and will adapt itself accordingly.

Still, this can be an invaluable asset to Fuzzer modules.

## Usage

### WebUI

The Web User Interface is basically a Sinatra app which acts as an Arachni XMLRPC client and connects to a running XMLRPC Dispatch server.

Thus, you first need to start a Dispatcher like so:
    $ arachni_xmlrpcd &

Then start the WebUI by running:
    $ arachni_web

_If you get any permission errors then you probably installed the Gem using 'sudo', so use 'sudo' to start the servers too._

And finally open up a browser window and visit: http://localhost:4567/

#### Options

You can see all available options using:
    $ arachni_web -h

#### Shutdown
You can kill the WebUI by sending _Ctrl+C_ to the console from which you started it.

However, in order to kill the Dispatcher (and all the processes in its pool) you will need to _killall -9 arachni_xmlrpcd_ (or _killall -9 ruby_ depending on your setup) or hunt them down manually.
This inconvenience is by design; it guarantees that Arachni instances will be available (and usable) instantly and that running scans will continue unaffected even if the dispatcher has (for some reason) died.

#### Parallel scans
As you might have guessed by the use of the word _pool_ in the previous paragraph, the WebUI allows you to run as many scans as you wish at the same time.
Of course, the amount of parallel scans you'll be able to perform will be limited by your available resources (Network bandwidth/RAM/CPU).

Should you shutdown the WebUI while a scan is running you'll be able to re-attach to the running process and view its progress or (if the scan has already finished) grab the report the next time you visit the WebUI.
In most cases, you won't even need to re-attach to a process in order to get the report of the finished scan, the WebUI's zombie reaper will grab and save the report for you.

#### General
In cases where the Dispatcher is started with its default settings on localhost (like the above example) the WebUI will connect to it automatically.

However, if you see an error message informing you that the WebUI could not find a dispatcher to connect to then you probably visited the WebUI before it had a chance to connect to the Dispatcher, you can just click on the "Dispatcher" tab to force it to try again; if the error does not re-appear then it connected successfully.

If you get a scary "Broken pipe" exception a simple refresh will solve the problem.

#### Remote deployment
As noted above, the WebUI is, in essence, a user-friendly Arachni XMLRPC client, this means that you can start a Dispatcher on a remote host and manage it via the WebUI.
Simple as that really.

#### Encryption & Authentication
WebUI-client (browser) and XMLRPC Client-Dispatch server authentication takes place using SSL certificate/key pairs.

These are the 3 basic models:

 - No encryption & no authentication -- Default behavior
 - Encryption & no authentication    -- Just enable SSL in the WebUI configuration file (_conf/webui.yaml_) and the Dispatcher and all components will generate their own certificate/key pairs and disable peer verification.
 - Encryption & authentication       -- Enable SSL and use your own cert/key pairs to authenticate clients to the WebUI and vice verse, and authenticate the XMLRPC clients controlled by the WebUI to the Dispatcher and vice versa.

However, you can go even further and create combinations specific to each component.

*Beware:* This interface is brand new so if you encounter any issues please do report them.

### Command line interface

The command-line interface is the oldest, most tested and thus more reliable.

#### Help
In order to see everything Arachni has to offer execute:
    $ arachni -h

Or visit the Wiki.

#### Examples
You can simply run Arachni like so:

    $ arachni http://test.com

which will load all modules and audit all forms, links and cookies.

In the following example all modules will be run against <i>http://test.com</i>, auditing links/forms/cookies and following subdomains --with verbose output enabled.<br/>
The results of the audit will be saved in the the file <i>test.com.afr</i>.

    $ arachni -fv http://test.com --report=afr:outfile=test.com.afr

The Arachni Framework Report (.afr) file can later be loaded by Arachni to create a report, like so:

    $ arachni --repload=test.com.afr --report=html:outfile=my_report.html

or any other report type as shown by:

    $ arachni --lsrep

#### You can make module loading easier by using wildcards (*) and exclusions (-).

To load all _xss_ modules using a wildcard:
    $ arachni http://example.net --mods=xss_*

To load all _audit_ modules using a wildcard:
    $ arachni http://example.net --mods=audit*

To exclude only the _csrf_ module:
    $ arachni http://example.net --mods=*,-csrf

Or you can mix and match; to run everything but the _xss_ modules:
    $ arachni http://example.net --mods=*,-xss_*

For a full explanation of all available options you can consult the [User Guide](http://github.com/Zapotek/arachni/wiki/User-guide).

#### Performing a comprehensive scan quickly

Arachni comes with a preconfigured profile (_profiles/comprehensive.afp_) for a comprehensive audit.
This profile loads all modules, audits links/forms/cookies and loads the HealthMap and Content-Types plugins.

You can use it like so:
    $ arachni --load-profile=profiles/comprehensive.afp http://example.net

#### Performing a full scan quickly

The _full_ profile adds header auditing to the _comprehensive_ profile.

_NOTICE: Auditing headers can increase scan time by an order of magnitude (depending on the website) and may be considered over-the-top in most scenarios._

You can use it like so:
    $ arachni --load-profile=profiles/full.afp http://example.net


_If you installed the Gem then you'll have to look for the "profiles" directory in your gems path._

## Installation

To install the Gem or work with the source code you'll also need the following system libraries:
    $ sudo apt-get install libxml2-dev libxslt1-dev libcurl4-openssl-dev libsqlite3-dev

You will also need to have Ruby 1.9.2 installed *including* the dev package/headers.<br/>
The prefered ways to accomplish this is by either using [RVM](http://rvm.beginrescueend.com/) or by downloading and compiling the source code for [Ruby 1.9.2](http://www.ruby-lang.org/en/downloads/) manually.

### Gem

To install Arachni:
    $ gem install arachni

### Source

If you want to clone the repository and work with the source code then you'll need to run the following to install all gem dependencies and Arachni:
    $ rake install


## Supported platforms

Arachni should work on all *nix and POSIX compliant platforms with Ruby
and the aforementioned requirements.

Windows users should run Arachni in Cygwin.

## Bug reports/Feature requests
Please send your feedback using Github's issue system at
[http://github.com/zapotek/arachni/issues](http://github.com/zapotek/arachni/issues).


## License
Arachni is licensed under the GNU General Public License v2.<br/>
See the [LICENSE](file.LICENSE.html) file for more information.


## Disclaimer
Arachni is free software and you are allowed to use it as you see fit.<br/>
However, I can't be held responsible for your actions or for any damage
caused by the use of this software.

![Arachni banner](http://zapotek.github.com/arachni/banner.png)
