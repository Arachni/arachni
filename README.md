# High Performance Grid (HPG) dev branch.

The Grid is highly experimental and far from properly tested, however if you're feeling brave keep reading.

## Installation

You first need to install the Arachni-RPC system from source (it's still under development so there's no gem yet):

    git clone git://github.com/Arachni/arachni-rpc.git
    cd arachni-rpc
    rake install

Then you'll have to do the same to get the latest Typhoeus code (still under dev, no gem yet as well):

    git clone git://github.com/dbalatero/typhoeus.git
    cd typhoeus
    gem build typhoeus.gemspec
    gem install typhoeus-0.2.4.gem

Then things go as usual:

    git clone git://github.com/Zapotek/arachni.git
    cd arachni
    git co grid
    rake install

## Setting up the High Performance Grid (HPG)

Pretty much the same as setting up the WebUI but instead of running only one Dispatcher you can run as many as you can handle.

In order to connect the Dispatchers into a grid you'll need to:

 - specify an IP address or hostname on which the Dispatcher will be accessible by the rest of the Grid nodes (i.e. other Dispatchers)
 - specify a neighbouring Dispatcher when running a new one
 - use different Pipe IDs -- these are used to identify independent bandwidth lines to the target in order to split the workload in a way that will aggregate the collective bandwidth

After that they will build their network themselves.

Here's how it's done:

Firing up the first one:

    arachni_rpcd --pipe-id="Pipe 1" --nickname="My Dispatcher" --address=192.168.0.1

Adding more to make a Grid:

    arachni_rpcd --pipe-id="Pipe 2" --nickname="My second Dispatcher" --address=192.168.0.2 --neighbour=192.168.0.1:7331

Lather, rinse, repeat:

    arachni_rpcd --pipe-id="Pipe 3" --nickname="My third Dispatcher" --address=192.168.0.3 --neighbour=192.168.0.2:7331

    arachni_rpcd --pipe-id="Pipe 4" --nickname="My forth Dispatcher" --address=192.168.0.4 --neighbour=192.168.0.3:7331

That sort of setup assumes that each Dispatcher is on a machine with independent bandwidth lines (to the target website at least).

If you want to, out of curiosity, start a few Dispatchers on localhost you will need to specify the ports:

    arachni_rpcd --pipe-id="Pipe 1" --nickname="My Dispatcher"

    arachni_rpcd --pipe-id="Pipe 2" --nickname="My second Dispatcher" --port=1111 --neighbour=localhost:7331

    arachni_rpcd --pipe-id="Pipe 3" --nickname="My third Dispatcher" --port=2222 --neighbour=localhost:1111

etc.

## Usage

After setting everything up you simply start the WebUI as usual.<br/>
When it asks you to specify a Dispatcher you pick one, enter it and the WebUI will grab its neighbours automatically.

Despite the fact that there haven't been any dramatic changes to the front-end of the WebUI you'll immediatly notice a sizable<br/>
performance increase, both when browsing around and when monitoring running scans.<br/>

You can find some more technical stuff here: http://trainofthought.segfault.gr/2011/07/29/arachni-grid-draft-design/

And some screenshots here: http://trainofthought.segfault.gr/2011/09/02/arachni-a-sneak-peek-at-the-grid-with-screenshots/

# Arachni - Web Application Security Scanner Framework
<table>
    <tr>
        <th>Version</th>
        <td>0.4</td>
    </tr>
    <tr>
        <th>Homepage</th>
        <td><a href="http://arachni.segfault.gr">http://arachni.segfault.gr</a></td>
    </tr>
    <tr>
        <th>Blog</th>
        <td><a href="http://trainofthought.segfault.gr/category/projects/arachni/">http://trainofthought.segfault.gr/category/projects/arachni/</a></td>
    <tr>
        <th>Github page</th>
        <td><a href="http://github.com/zapotek/arachni">http://github.com/zapotek/arachni</a></td>
     <tr/>
    <tr>
        <th>Documentation</th>
        <td><a href="http://github.com/Zapotek/arachni/wiki">http://github.com/Zapotek/arachni/wiki</a></td>
    </tr>
    <tr>
        <th>Code Documentation</th>
        <td><a href="http://zapotek.github.com/arachni/">http://zapotek.github.com/arachni/</a></td>
    </tr>
    <tr>
        <th>Google Group</th>
        <td><a href="http://groups.google.com/group/arachni">http://groups.google.com/group/arachni</a></td>
    </tr>
    <tr>
       <th>Author</th>
       <td><a href="mailto:tasos.laskos@gmail.com">Tasos</a> "<a href="mailto:zapotek@segfault.gr">Zapotek</a>" <a href="mailto:tasos.laskos@gmail.com">Laskos</a></td>
    </tr>
    <tr>
        <th>Twitter</th>
        <td><a href="http://twitter.com/Zap0tek">@Zap0tek</a></td>
    </tr>
    <tr>
        <th>Copyright</th>
        <td>2010-2011</td>
    </tr>
    <tr>
        <th>License</th>
        <td><a href="file.LICENSE.html">GNU General Public License v2</a></td>
    </tr>
</table>

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

 - Filters for redundant pages like galleries, catalogs, etc based on regular expressions and counters.
 - URL exclusion filter based on regular expressions.
 - URL inclusion filter based on regular expressions.
 - Can optionally follow subdomains.
 - Adjustable link count limit.
 - Adjustable redirect limit.
 - Modular path extraction via "Path Extractor" components.

### HTML Parser

Can extract and analyze:

 - Forms
 - Links
 - Cookies
 - Headers

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
    - Passive Proxy -- Analyzes requests and responses between the web app and the browser assisting in AJAX audits, logging-in and/or restricting the scope of the audit
    - Form based AutoLogin
    - Dictionary attacker for HTTP Auth
    - Dictionary attacker for form based authentication
    - Profiler -- Performs taint analysis (with benign inputs) and response time analysis
    - Cookie collector -- Keeps track of cookies while establishing a timeline of changes
    - Healthmap -- Generates sitemap showing the health of each crawled/audited URL
    - Content-types -- Logs content-types of server responses aiding in the identification of interesting (possibly leaked) files
    - WAF (Web Application Firewall) Detector -- Establishes a baseline of normal behavior and uses rDiff analysis to determine if malicious inputs cause any behavioral changes
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

### [WebUI](https://github.com/Zapotek/arachni/wiki/Web-user-interface)


### [Command line interface](https://github.com/Zapotek/arachni/wiki/Command-line-user-interface)

## Installation

### CDE packages for Linux

Arachni is released as [CDE packages](http://stanford.edu/~pgbovine/cde.html) for your convinience.<br/>
CDE packages are self contained and thus alleviate the need for Ruby and other dependencies to be installed or root access.<br/>
You can download the latest CDE package from the [download](https://github.com/Zapotek/arachni/downloads) page and escape the dependency hell.<br/>
If you decide to go the CDE route you can skip the rest, you're done.

Due to some incompatibility this release does not have a CDE package yet.

### Gem

To install the Gem or work with the source code you'll also need the following system libraries:

    $ sudo apt-get install libxml2-dev libxslt1-dev libcurl4-openssl-dev libsqlite3-dev

You will also need to have Ruby 1.9.2 installed *including* the dev package/headers.<br/>
The prefered ways to accomplish this is by either using [RVM](http://rvm.beginrescueend.com/) or by downloading and compiling the source code for [Ruby 1.9.2](http://www.ruby-lang.org/en/downloads/) manually.


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
