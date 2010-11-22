# Experimental branch
Intended for research and experimental development **only**.

End-users should check out the links bellow.

## Current branch goals
 - Provide integration with the Metasploit framework to assist with automated and manual exploitation through:
   - ArachniMetareport. -- **Done**
   - Arachni plug-in for the Metasploit framework. -- **Done**
   - Advanced generic webapp exploit modules for the Metasploit framework. -- **Done**
 - Add reusable/persistent XML-RPC server and command line XMLRPC client. -- **Done**
 - Modify Anemone to support modules for path extraction. -- **Done**
 - Path extractors
   - Generic -- extracts URLs from arbitrary text -- **Done**
   - Anchors -- **Done**
   - Form actions -- **Done**
   - Frame sources -- **Done**
   - Links -- **Done**
   - META refresh -- **Done**
   - Script 'src' and script code -- **Done**
   - Sitemap -- **Done**
 - Modify Anemone to use Typhoeus instead of Net::HTTP -- adding NTML auth and other goodies. -- **Done**
 - Refactor, re-organize and clean up the framework code and architecture. -- **Done**
 - Add plug-in support -- allowing the framework to be extended with virtually any functionality.  -- **Done**
 - Add the following plug-ins:
   - Passive proxy -- **Done**
   - Automated login -- **Done**
 - Add the following modules:
   - Audit:
     - XPath injection  -- **Done**
     - LDAP injection  -- **Done**
   - Recon:
     - Robot file reader  -- **Done** (in the Common Files module)
     - Allowed HTTP methods  -- **Done**
     - WebDAV detection  -- **Done**
     - XST  -- **Done**
     - CVS/SVN user disclosure  -- **Done**
     - Private IP address disclosure  -- **Done**

# Arachni - Web Application Security Scanner Framework
**Version**:     0.2.1<br/>
**Homepage**:     [http://github.com/zapotek/arachni](http://github.com/zapotek/arachni)<br/>
**News**:     [http://trainofthought.segfault.gr/category/projects/arachni/](http://trainofthought.segfault.gr/category/projects/arachni/)<br/>
**Documentation**:     [http://github.com/Zapotek/arachni/wiki](http://github.com/Zapotek/arachni/wiki)<br/>
**Code Documentation**:     [http://zapotek.github.com/arachni/](http://zapotek.github.com/arachni/)<br/>
**Author**:       [Tasos](mailto:tasos.laskos@gmail.com) "[Zapotek](mailto:zapotek@segfault.gr)" [Laskos](mailto:tasos.laskos@gmail.com)<br/>
**Copyright**:    2010<br/>
**License**:      [GNU General Public License v2](file.LICENSE.html)

![Arachni logo](http://zapotek.github.com/arachni/logo.png)

Kindly sponsored by: [![NopSec](http://zapotek.github.com/arachni/nopsec_logo.png)](http://www.nopsec.com)

## Synopsis

{Arachni} is a feature-full, modular, high-performance Ruby framework aimed towards helping
penetration testers and administrators evaluate the security of web applications.

{Arachni} is smart, it trains itself by learning from the HTTP responses it receives
during the audit process.<br/>
Unlike other scanners, Arachni takes into account the dynamic
nature of web applications and can detect changes caused while travelling<br/>
through the paths of a web application's cyclomatic complexity.<br/>
This way attack/input vectors that would otherwise be undetectable by non-humans
are seamlessly handled by Arachni.

Finally, Arachni yields great performance due to its asynchronous HTTP  model (courtesy of Typhoeus).<br/>
Thus, you'll only be limited by the responsiveness of the server under audit and your available bandwidth.

Note: Despite the fact that Arachni is mostly targeted towards web application security,
it can easily be used for general purpose scraping, data-mining, etc with the addition of custom modules.


{Arachni} offers:

**1 A stable, efficient, high-performance framework**<br/>

Module and report writers are allowed to easily and quickly create and deploy modules
with the minimum amount of restrictions imposed upon them, while provided
with the necessary infrastructure to accomplish their goals.<br/>
Furthermore, they are encouraged to take full advantage of the Ruby language
under a unified framework that will increase their productivity
without stifling them or complicating their tasks.<br/>
Basically, Arachni gives you the right tools for the job and gets the hell out of your way.

**2 Simplicity**<br/>
Although some parts of the Framework are fairly complex you will never have to deal them directly.<br/>
From a user's or a module developer's point of view everything appears simple and straight-forward
all the while providing power, performance and flexibility.

There are only a couple of rules a developer needs to follow:

- Implement an abstract class
- Do his thing

That's pretty much all you are expected and need to do...
A glance at an existing report or module will be all you need to get you going.

Users just need to take a look at the help output.<br/>
However, extensive [documentation](http://github.com/Zapotek/arachni/wiki) exists for those who want to be aware of all the details.


## Feature List

### General

 - Cookie-jar support
 - SSL support.
 - User Agent spoofing.
 - Proxy support for SOCKS4, SOCKS4A, SOCKS5, HTTP/1.1 and HTTP/1.0.
 - Proxy authentication.
 - Site authentication (Automated form-based, Cookie-Jar, Basic-Digest, NTLM and others)
 - Highlighted command line output.
 - UI abstraction.
 - Pause/resume functionality.
    - Interrupts pause the system, the user then has the option to either resume or exit.
 - High performance asynchronous HTTP requests.


### Website Crawler ({Arachni::Spider})

The crawler is provided by [Anemone](http://anemone.rubyforge.org/) -- with some slight modifications to accommodate extra features.

 - Filters for redundant pages like galleries, catalogs, etc based on regular expressions and counters.
 - URL exclusion filter based on regular expressions.
 - URL inclusion filter based on regular expressions.
 - Stays in domain by default and it'll probably stay that way.
 - Can optionally follow subdomains.
 - Multi-threaded with adjustable thread count.
 - Adjustable depth limit.
 - Adjustable  link count limit.
 - Adjustable redirect limit.



### HTML Parser ({Arachni::Parser})

Can extract and analyze:

 - Forms
 - Links
 - Cookies

The analyzer can graciously handle badly written HTML code
due to the combination of regular expression analysis and [Nokogiri](http://nokogiri.org/) HTML parser.

This way the system can be extended to be able to handle virtually anything.

###  Module Management ({Arachni::Module})

 - Modular design
    - Very simple and easy to use module API providing access at multiple levels.
 - Helper audit methods
    - For forms, links and cookies.
    - Writing RFI, SQL injection, XSS etc mods is a matter of minutes if not seconds.
 - Helper {Arachni::HTTP} interface
    - A high-performance, simple and easy to use Typhoeus wrapper.

You can find a tutorial module here: {Arachni::Modules::SimpleRFI}

### Report Management ({Arachni::Report})

 - Modular design
    - Very easy to add new reports.
    - Reports are similar to modules...but a lot simpler.


You can find an up-to-date sample report here: {Arachni::Reports::AP}<br/>
And a more complex HTML report here: {Arachni::Reports::HTML}


### Plug-in Management ({Arachni::Plugin})

 - Modular design
    - Very easy to add new plug-ins.
    - Plug-ins are framework demi-gods, they have direct access to the framework instance.
    - Can be used to add any functionality to Arachni.


### Trainer subsystem ({Arachni::Module::Trainer})

The Trainer is what enables Arachni to learn from the scan it performs
and incorporate that knowledge, on the fly, for the duration of the audit.

Modules have the ability to individually force the Framework to learn from the HTTP responses they are
going to induce.<br/>
However, this is usually not required since Arachni is aware of which requests are more likely
to uncover new elements or attack vectors and will adapt itself accordingly.

Still, this can be an invaluable asset to Fuzzer modules.

## Usage

       Arachni - Web Application Security Scanner Framework v0.2.1 [0.2]
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
                                  (Default: 200)
                                  (NOTE: If your scan seems unresponsive try lowering the limit.)

    --http-harvest-last         build up the HTTP request queue of the audit for the whole site
                                 and harvest the HTTP responses at the end of the crawl.
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
                                  (Use '*' to deploy all modules)
                                  (You can exclude modules by prefixing their name with a dash:
                                      --mods=*,-backup_files,-xss
                                   The above will load all modules except for the 'backup_files' and 'xss' modules. )

### Reports

    --lsrep                       list available reports

    --repsave=<file>              save the audit results in <file>
                                    (The file will be saved with an extention of: .afr)

    --repload=<file>              load audit results from <file>
                                    (Allows you to create a new reports from old/finished scans.)

    --report='<report>:<optname>=<val>,<optname2>=<val2>,...'

                                  <repname>: the name of the report as displayed by '--lsrep'
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

    --proxy-type=<type>         proxy type can be either socks or http
                                  (Default: http)


### Examples

As of v0.2.1 you can simply run Arachni like so:

    $ ./arachni.rb http://test.com

which will load all modules and audit all forms, links and cookies.

In the following example all modules will be run against <i>http://test.com</i>, auditing links/forms/cookies and following subdomains --with verbose output enabled.<br/>
The results of the audit will be saved in the the file <i>test.com.afr</i>.

    $ ./arachni.rb -gpcfv --mods=* http://test.com --repsave=test.com

The Arachni Framework Report (.afr) file can later be loaded by Arachni to create a report, like so:

    $ ./arachni.rb --report=html --repload=test.com.afr --repsave=my_report

or any other report type as shown by:

    $ ./arachni.rb --lsrep

For a full explenation of all available options you can consult the [User Guide](http://github.com/Zapotek/arachni/wiki/User-guide).

## Requirements

  * ruby1.9.1 or later
  * Nokogiri
  * Typhoeus
  * Awesome print
  * Liquid (For {Arachni::Reports::HTML} reporting)
  * Yardoc (if you want to generate the documentation)

Run the following to install all required system libraries:
    sudo apt-get install libxml2-dev libxslt1-dev libcurl4-openssl-dev ruby1.9.1-full ruby1.8-dev rubygems

(Adapt the above line to your Linux distro.)

Run the following to install all gem dependencies:
    sudo gem install nokogiri typhoeus awesome_print liquid yard

(Make sure you install the gems with gem version 1.9.1 and run arachni with ruby version 1.9.1)

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
