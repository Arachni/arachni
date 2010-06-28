=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

#
# Outputs Arachni banner.<br/>
# Displays version number, revision number, author details etc.
#
# @see VERSION
# @see REVISION
#
# @return [void]
#
def banner

  puts 'Arachni v' + VERSION + ' [' + REVISION + '] initiated.
     Author: Anastasios "Zapotek" Laskos <zapotek@segfault.gr>
     Website: http://www.segfault.gr

'

end

#
# Outputs help/usage information.<br/>
# Displays supported options and parameters.
#
# @return [void]
#
def usage
  puts <<USAGE
Usage:  arachni \[options\] url

Supported options:
  
  General ----------------------

  -h
  --help                      output this
  
  -r
  --resume                    resume suspended session
  
  -v                          be verbose
  
  --cookie-jar=<cookiejar>    specify cookiejar
  
  --user-agent=<user agent>   specify user agent
  
  
  Crawler -----------------------
  
  -e <regex>
  --exclude=<regex>           exclude urls matching regex
  
  -i <regex>
  --include=<regex>           include urls matching this regex only

  -f
  --follow-subdomains         follow links to subdomains (default: off)
  
  --obey-robots-txt           obey robots.txt file (default: false)
  
  --depth=<number>            depth limit (default: inf)
                                How deep Arachni should go into the site structure.
                                
  --link-count=<number>       how many links to follow (default: inf)                              
  
  --redirect-limit=<number>   how many redirects to follow (default: inf)

  --threads=<number>          how many threads to instantiate (default: 3)
                                More threads does not necessarily mean more speed,
                                be careful when adjusting thread count.

  Auditor ------------------------                                
                                
  -g
  --audit-links               audit link variables (GET)
  
  -p
  --audit-forms               audit form variables
                                (usually POST, can also be GET)
  
  -c
  --audit-cookies             audit cookies (COOKIE)

  
  Modules ------------------------
                                                                    
  -l
  --lsmod                     list available modules

    
  -m <modname,modname..>
  --mods=<modname,modname..>  comma separated list of modules to deploy
  

  Proxy --------------------------
  
  --proxy=<server:port>       specify proxy
  
  --proxy-auth=<user:passwd>  specify proxy auth credentials
  
  --proxy-type=<type>         proxy type can be either socks or http
                              (default: http)
  

USAGE

end
