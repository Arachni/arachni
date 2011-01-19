# Arachni - Web Application Security Scanner Framework
**Version**:     0.2.2<br/>
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
    - HTML
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

### Trainer subsystem

The Trainer is what enables Arachni to learn from the scan it performs and incorporate that knowledge, on the fly, for the duration of the audit.

Modules have the ability to individually force the Framework to learn from the HTTP responses they are going to induce.<br/>
However, this is usually not required since Arachni is aware of which requests are more likely to uncover new elements or attack vectors and will adapt itself accordingly.

Still, this can be an invaluable asset to Fuzzer modules.

## Usage

       Arachni - Web Application Security Scanner Framework v0.2.2 [0.2]
       Author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
                                      <zapotek@segfault.gr>
               (With the support of the community and the Arachni Team.)

       Website:       http://github.com/Zapotek/arachni
       Documentation: http://github.com/Zapotek/arachni/wiki


      Usage:  arachni [options] url

      Supported options:


### General

    -h
    --help                      output this

    -v                          be verbose

    --debug                     show what is happening internally
                                  (You should give it a shot sometime ;) )

    --only-positives            echo positive results *only*

    --http-req-limit            concurent HTTP requests limit
                                  (Be carefull not to kill your server.)
                                  (Default: 60)
                                  (*NOTE*: If your scan seems unresponsive try lowering the limit.)

    --http-harvest-last         build up the HTTP request queue of the audit for the whole site
                                 and harvest the HTTP responses at the end of the crawl.
                                 (In some test cases this option has split the scan time in half.)
                                 (Default: responses will be harvested for each page)
                                 (*NOTE*: If you are scanning a high-end server and
                                   you are using a powerful machine with enough bandwidth
                                   *and* you feel dangerous you can use
                                   this flag with an increased '--http-req-limit'
                                   to get maximum performance out of your scan.)
                                 (*WARNING*: When scanning large websites with hundreads
                                  of pages this could eat up all your memory pretty quickly.)

    --cookie-jar=<cookiejar>    netscape HTTP cookie file, use curl to create it


    --user-agent=<user agent>   specify user agent

    --authed-by=<who>           who authorized the scan, include name and e-mail address
                                  (It'll make it easier on the sys-admins during log reviews.)
                                  (Will be appended to the user-agent string.)

### Profiles

    --save-profile=<file>       save the current run profile/options to <file>
                                  (The file will be saved with an extention of: .afp)

    --load-profile=<file>       load a run profile from <file>
                                  (Can be used multiple times.)
                                  (You can complement it with more options, except for:
                                      * --mods
                                      * --redundant)

    --show-profile              will output the running profile as CLI arguments

### Crawler

    -e <regex>
    --exclude=<regex>           exclude urls matching regex
                                  (Can be used multiple times.)

    -i <regex>
    --include=<regex>           include urls matching this regex only
                                  (Can be used multiple times.)

    --redundant=<regex>:<count> limit crawl on redundant pages like galleries or catalogs
                                  (URLs matching <regex> will be crawled <count> links deep.)
                                  (Can be used multiple times.)

    -f
    --follow-subdomains         follow links to subdomains (default: off)

    --obey-robots-txt           obey robots.txt file (default: off)

    --depth=<number>            depth limit (default: inf)
                                  (How deep Arachni should go into the site structure.)

    --link-count=<number>       how many links to follow (default: inf)

    --redirect-limit=<number>   how many redirects to follow (default: inf)

    --spider-first              spider first, audit later


### Auditor

    -g
    --audit-links               audit link variables (GET)

    -p
    --audit-forms               audit form variables
                                  (usually POST, can also be GET)

    -c
    --audit-cookies             audit cookies (COOKIE)

    --exclude-cookie=<name>     cookies not to audit
                                  (You should exclude session cookies.)
                                  (Can be used multiple times.)

    --audit-headers             audit HTTP headers
                                  (*NOTE*: Header audits use brute force.
                                   Almost all valid HTTP request headers will be audited
                                   even if there's no indication that the web app uses them.)
                                  (*WARNING*: Enabling this option will result in increased requests,
                                   maybe by an order of magnitude.)

### Modules

    --lsmod=<regexp>            list available modules based on the provided regular expression
                                  (If no regexp is provided all modules will be listed.)
                                  (Can be used multiple times.)


    -m <modname,modname..>
    --mods=<modname,modname..>  comma separated list of modules to deploy
                                  (Use '*' as a module name to deploy all modules or inside module names like so:
                                      xss_*   to load all xss modules
                                      sqli_*  to load all sql injection modules
                                      etc.

                                   You can exclude modules by prefixing their name with a dash:
                                      --mods=*,-backup_files,-xss
                                   The above will load all modules except for the 'backup_files' and 'xss' modules.

                                   Or mix and match:
                                      -xss_*   to unload all xss modules. )

### Reports

    --lsrep                       list available reports

    --repload=<file>              load audit results from an .afr file
                                    (Allows you to create new reports from finished scans.)

    --report='<report>:<optname>=<val>,<optname2>=<val2>,...'

                                  <report>: the name of the report as displayed by '--lsrep'
                                    (Default: stdout)
                                    (Can be used multiple times.)

### Plugins

    --lsrep                       list available reports

    --repload=<file>              load audit results from an .afr file
                                    (Allows you to create new reports from finished scans.)

    --report='<report>:<optname>=<val>,<optname2>=<val2>,...'

                                  <report>: the name of the report as displayed by '--lsrep'
                                    (Default: stdout)
                                    (Can be used multiple times.)

### Plugins

    --lsplug                      list available plugins

    --plugin='<plugin>:<optname>=<val>,<optname2>=<val2>,...'

                                  <plugin>: the name of the plugin as displayed by '--lsplug'
                                    (Can be used multiple times.)


### Proxy

    --proxy=<server:port>       specify proxy

    --proxy-auth=<user:passwd>  specify proxy auth credentials

    --proxy-type=<type>           proxy type can be http, http_1_0, socks4, socks5, socks4a
                                  (Default: http)


### Examples

You can simply run Arachni like so:

    $ ./arachni.rb http://test.com

which will load all modules and audit all forms, links and cookies.

In the following example all modules will be run against <i>http://test.com</i>, auditing links/forms/cookies and following subdomains --with verbose output enabled.<br/>
The results of the audit will be saved in the the file <i>test.com.afr</i>.

    $ ./arachni.rb -fv http://test.com --report=afr:outfile=test.com.afr

The Arachni Framework Report (.afr) file can later be loaded by Arachni to create a report, like so:

    $ ./arachni.rb --repload=test.com.afr --report=html:outfile=my_report.html

or any other report type as shown by:

    $ ./arachni.rb --lsrep

#### You can make module loading easier by using wildcards (*) and exclusions (-).

To load all _xss_ modules using a wildcard:
    $ ./arachni.rb http://example.net --mods=xss_*

To load all _audit_ modules using a wildcard:
    $ ./arachni.rb http://example.net --mods=audit*

To exclude only the _csrf_ module:
    $ ./arachni.rb http://example.net --mods=*,-csrf

Or you can mix and match; to run everything but the _xss_ modules:
    $ ./arachni.rb http://example.net --mods=*,-xss_*

For a full explanation of all available options you can consult the [User Guide](http://github.com/Zapotek/arachni/wiki/User-guide).

## Requirements

Arachni is also released as [CDE packages](http://stanford.edu/~pgbovine/cde.html) for 32bit and 64bit architectures.<br/>
CDE packages are self contained and thus alleviate the need for Ruby and other dependencies to be installed.<br/>
You can choose the CDE package that suits you best from the [download](https://github.com/Zapotek/arachni/downloads) page and escape the dependency hell.<br/>
If you decide to go the CDE route you can skip the rest, you're done.

_The CDE packages are for Linux **only** and do not include the XMLRPC server componenets for security reasons._

Otherwise, in order to use Arachni you will need the following:

  * ruby1.9.2 (*pay close attention to the version*)
  * Nokogiri
  * Typhoeus
  * Awesome print
  * Liquid (for HTML reporting)
  * Yardoc (to generate the documentation)
  * Robots

Run the following to install all required system libraries:
    sudo apt-get install libxml2-dev libxslt1-dev libcurl4-openssl-dev

_Adapt the above line to your Linux distro._

Run the following to install all gem dependencies:
    sudo gem install nokogiri typhoeus awesome_print liquid yard robots

If you already have the above gems install make sure that you have the latest versions:
    sudo gem update

If you wish to use the XMLRPC Dispatcher and Monitor (_arachni_xmlrpcd.rb_/_arachni_xmlrpcd_monitor.rb_) you'll also need to:

  * install [sys-proctable](https://github.com/djberg96/sys-proctable/wiki)
  * sudo gem install terminal-table


_If you have more than one Ruby version installed make sure that you install the gems and run Arachni with the proper version._



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
