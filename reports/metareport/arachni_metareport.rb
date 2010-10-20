=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

#
# ArachniMetareport
#
# This class is used by Arachni to save a report detailing all exploitable
# vulnerabilities.
#
# A serialized array holding instances of this class will be loaded by
# the Metasploit Framework.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class ArachniMetareport


    attr_accessor :host
    attr_accessor :port
    attr_accessor :vhost
    attr_accessor :ssl
    
    attr_accessor :path
    attr_accessor :query
    attr_accessor :method
    attr_accessor :params
    attr_accessor :pname
    attr_accessor :proof
    attr_accessor :risk
    
    attr_accessor :name
    attr_accessor :description
    attr_accessor :category
    
    attr_accessor :exploit
    
    #
    # From Metasploit's report_web_vuln() in: lib/msf/core/db.rb
    #
    # opts MUST contain
    #  :host     -- the ip address of the server hosting the web site
    #  :port     -- the port number of the associated web site
    #  :vhost    -- the virtual host for this particular web site
    #  :ssl      -- whether or not SSL is in use on this port
    #  :path      -- the virtual host name for this particular web site
    #  :query     -- the query string appended to the path (not valid for GET method flaws)
    #  :method    -- the form method, one of GET, POST, or PATH
    #  :params    -- an ARRAY of all parameters and values specified in the form
    #  :pname     -- the specific field where the vulnerability occurs
    #  :proof     -- the string showing proof of the vulnerability
    #  :risk      -- an INTEGER value from 0 to 5 indicating the risk (5 is highest)
    #  :name      -- the string indicating the type of vulnerability
    #
    def initialize( opts = {} )
        opts.each {
            |k, v|
            begin
                send( "#{k.to_s.downcase}=", v )
            rescue Exception => e
            end
        }
    end
    
end
