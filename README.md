Arachni - Web Application Vulnerability Scanning Framework
====================================
**Last change**:  $Id$<br/>
**Homepage**:     [http://sourceforge.net/apps/trac/arachni/wiki](http://sourceforge.net/apps/trac/arachni/wiki)<br/>
**Documentation**:     [http://arachni.sourceforge.net/](http://arachni.sourceforge.net/)<br/>
**SourceForge Home**:     [http://sourceforge.net/projects/arachni/](http://sourceforge.net/projects/arachni/)   
**SVN**:          [https://arachni.svn.sourceforge.net/svnroot/arachni/trunk](https://arachni.svn.sourceforge.net/svnroot/arachni/trunk)   
**Author**:       [Anastasios](mailto:tasos.laskos@gmail.com) "[Zapotek](mailto:zapotek@segfault.gr)" [Laskos](mailto:tasos.laskos@gmail.com)  
**Copyright**:    2010    
**License**:      GNU General Public License v2    

Synopsis
--------

{Arachni} is a feature-full and modular Ruby framework that allows
penetration testers and administrators to evaluate the security of web applications.

{Arachni} is smart, it trains itself with every HTTP response it receives
during the audit process.<br/>
Unlike other scanners, Arachni takes into account the dynamic
nature of web applications and can detect changes caused while travelling<br/>
through each path of a web application's cyclomatic complexity.<br/>
This way attack/input vectors that would otherwise be undetectable by non-humans
are seamlessly handled by Arachni.
 

The project aims to:

**1 Provide a stable and efficient framework**<br/>
Developers should be allowed to easily and quickly create and deploy modules
with the minimum amount of restrictions imposed upon them, while provided
with the necessary infrastructure to accomplish their goals.<br/>
Module writers should be able to take full advantage of the Ruby language
under a unified framework that will increase their productivity
without stifling them or complicating their tasks.<br/>
Basically, give them the right tools for the job and get the hell out of their way.
 
**2 Be simple**<br/>
Well, not simple in general...some parts of the framework are fairly complex.<br/>
However, the module and report APIs are very similar and very simple.<br/>
There are only a couple of rules you should follow:

- Implement an abstract class
- Do your thing

That's pretty much all...

**3 Be developer and user friendly**<br/>
Users should be able to make the most out of Arachni without being confused or
overwhelmed.<br/>
Developers unfamiliar with the framework should be able to write working modules
and reports immediately after a small glance at an existing one.


Feature List
------------

**General**

 - Cookie-jar support
 - SSL support.
 - User Agent spoofing.
 - Proxy support for SOCKS and HTTP(S).
    - SOCKS support is kindly provided by [socksify](http://socksify.rubyforge.org/).
 - Proxy authentication.
 - Site authentication.
 - Local DNS cache limits name resolution queries.
 - Custom output lib.
    - The system uses its own print wrappers to output messages.<br/>
    Will make it easier to implement other UIs in the future.
 - Highlighted command line output, Metasploit style.
 - Run mods last option.
    - Allows to run the modules after site analysis has concluded.
 - UI abstraction.
    - Only {Arachni::UI::CLI} for the time being but WebUI & GUI are relatively easy to implement now.
 - Traps Ctrl-C interrupt.
    - Interrupts pause the system, the user then has the option to either resume or exit.
  
 
** Website Crawler ** ({Arachni::Spider})

The crawler is provided by [Anemone](http://anemone.rubyforge.org/) with some slight modifications to accommodate extra features.

 - Filters for redundant pages like galleries, catalogs, etc based on regular expressions and counters.
 - URL exclusion filter based on regular expressions.
 - URL inclusion filter based on regular expressions.
 - Stays in domain by default and it'll probably stay that way.
 - Can optionally follow subdomains.
 - Multi-threaded with adjustable thread count.
 - Adjustable depth limit.
 - Adjustable  link count limit.
 - Adjustable redirect limit.
 
 
 
** HTML Analyzer ** ({Arachni::Analyzer})

Can extract and analyze:

 - Forms
 - Links
 - Cookies

The analyzer can graciously handle badly written HTML code
due to the combination of regular expression analysis and [Nokogiri](http://nokogiri.org/) HTML parser.

The analyzer serves as the first layer of HTML analysis.<br/>
More complex analysis, for JS, AJAX, Java Applets etc, can be achieved by adding data-mining/audit pairs of modules
like:<br/>
- {Arachni::Modules::Recon::ExtractObjects}<br/>
- {Arachni::Modules::Audit::AuditObjects}

This way the system can be extended to be able to handle virtually anything.

**  Module Management ** ({Arachni::Module})

 - Modular design
    - Very simple and easy to use module API providing access at multiple levels.
 - Helper audit methods
    - For forms, links and cookies.
    - Writing RFI, SQL injection, XSS etc mods is a matter of minutes if not seconds.
 - Helper {Arachni::Module::HTTP} interface
    - A pretty and easy to use Net::HTTP wrapper.
 - Multi-threaded module execution with adjustable thread count.

You can find an tutorial module here: {Arachni::Modules::Audit::SimpleRFI}

**  Report Management ** ({Arachni::Report})

 - Modular design
    - Very easy to add new reports.
    - Reports are similar to modules...but a lot simpler.


You can find an up-to-date sample report here: {Arachni::Reports::AP}<br/>
And a more complex HTML report here: {Arachni::Reports::HTML} 


Usage
-----

  Usage:  arachni [options] url
  
  Supported options:
    
  
**General**
  
    -h
    --help                      output this
    
    -r
    --resume                    resume suspended session
    
    -v                          be verbose

    --debug                     show debugging output
    
    --only-positives            echo positive results *only*
  
    --threads=<number>          how many threads to instantiate
                                  If no thread limit has been specified
                                    each module will run in its own thread.
                                  
    --cookie-jar=<cookiejar>    netscape HTTP cookie file, use curl to create it
                                                                 
    
    --user-agent=<user agent>   specify user agent
    
    --authed-by=<who>           who authorized the scan, include name and e-mail address
                                  It'll make it easier on the sys-admins.
                                  (Will be appended to the user-agent string.)
    
    --save-profile=<file>       saves the current run profile/options to <file>
                                  (The file will be saved with an extention of: .afp)
                                  
    --load-profile=<file>       loads a run profile from <file>
                                  (You can complement it with more options, except for:
                                      * --mods
                                      * --redundant)
                                  
    
**Crawler**
    
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
                                  How deep Arachni should go into the site structure.
                                  
    --link-count=<number>       how many links to follow (default: inf)                              
    
    --redirect-limit=<number>   how many redirects to follow (default: inf)
  
    
**Auditor**
                                  
    -g
    --audit-links               audit link variables (GET)
    
    -p
    --audit-forms               audit form variables
                                  (usually POST, can also be GET)
    
    -c
    --audit-cookies             audit cookies (COOKIE)
  
    --exclude-cookie=<name>     cookies not to audit
                                  You should exclude session cookies.
                                  (Can be used multiple times.)
    
    --audit-headers             audit HTTP headers
  
    
**Modules**
                                                                      
    --lsmod                     list available modules
  
      
    -m <modname,modname..>
    --mods=<modname,modname..>  comma separated list of modules to deploy
                                  (use '*' to deploy all modules)
    
    --mods-run-last             run modules after the website has been analyzed
                                  (default: modules are run on every page
                                    encountered to minimize network latency.) 


**Reports**
    
    --lsrep                       list available reports
    
    --repsave=<file>              saves the audit results in <file>
                                    (The file will be saved with an extention of: .afr)               
    
    --repload=<file>              loads audit results from <file>
                                  and lets you create a new report
    
    --repopts=<option1>:<value>,<option2>:<value>,...
                                  Set options for the selected reports.
                                  (One invocation only, options will be applied to all loaded reports.)
                                  
    --report=<repname>          <repname>: the name of the report as displayed by '--lsrep'
                                  (default: stdout)
                                  (Can be used multiple times.)
                                  
                                  
**Proxy**
    
    --proxy=<server:port>       specify proxy
    
    --proxy-auth=<user:passwd>  specify proxy auth credentials
    
    --proxy-type=<type>         proxy type can be either socks or http
                                  (default: http)
                                  
    
**Example**

In the following example all modules will be run against <i>http://test.com</i>
, auditing links/forms/cookies and following subdomains --with verbose output enabled.<br/>
The results of the audit will be saved in the the file <i>test.com.afr</i>.  
    
    $ ./arachni_cli.rb -gpcfv --mods=* http://test.com --repsave=test.com

The Arachni Framework Report (.afr) file can later be loaded by Arachni to create a report, like so:

    $ ./arachni_cli.rb --repload=test.com.afr --report=txt --repsave=my_report.txt


Requirements
-----
    
  * ruby1.9.1 or later
  * Nokogiri
    - sudo gem install nokogiri
  * Anemone
    - sudo gem install anemone
  * Sockify
    - sudo gem install socksify
  * Awesome print
    - sudo gem install awesome_print
  * Liquid (For {Arachni::Reports::HTML} reporting)
    - sudo gem install liquid  
  * Yardoc (if you want to generate the documentation)


Supported platforms
----
Arachni should work on all *nix and POSIX compliant platforms with Ruby
and the aforementioned requirements.

Windows users should run Arachni in Cygwin.

Bug reports/Feature requests
-----
Please send your feedback using Github's issue system at 
[http://github.com/Zapotek/arachni/issues](http://github.com/Zapotek/arachni/issues).


License
-----
Arachni is licensed under the GNU General Public License v2.<br/>
See the "LICENSE" file for more information.


Disclaimer
-----
Arachni is free software and you are allowed to use it as you see fit.<br/>
However, I can't be held responsible for your actions or for any damage
caused by the use of this software.
