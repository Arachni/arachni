=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
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

    #
    # The IP address of the datastore_bak
    #
    # @return [String]
    #
    attr_accessor :host
    
    #
    # The port number of the associated web site
    #
    # @return   [Integer]
    #
    attr_accessor :port
    
    #
    # The virtual host for this particular web site
    #
    # @return   [Integer]
    #
    attr_accessor :vhost
    
    #
    # Whether or not SSL is in use on this port
    #
    # @return   [Bool]
    #
    attr_accessor :ssl
    
    #
    # Path of the vulnerable script
    #
    # @return   [String]
    #
    attr_accessor :path
    
    #
    # Query part of the vulnerable URI
    #
    # @return   [Bool]
    #
    attr_accessor :query
    
    #
    # HTTP method used for the vulnerability
    #
    # The MSF currently supports GET/POST/PATH only, although Arachni will also
    # provide COOKIE and HEADER if that's the case.
    #
    # @return   [String]
    #
    attr_accessor :method
    
    #
    # Parameters used for the vulnerability
    #
    # @return   [Hash]
    #
    attr_accessor :params
    
    #
    # Headers used for the vulnerability
    #
    # Contains cookies.
    #
    # @return   [Hash]
    #
    attr_accessor :headers
    
    #
    # The name of the vulnerable field
    #
    # @return   [String]
    #
    attr_accessor :pname
    
    #
    # A string showing proof of the vulnerability
    #
    # @return   [String]
    #
    attr_accessor :proof
    
    #
    # An integer value from 0 to 5 indicating the risk (5 is highest)
    #
    # @return   [Integer]
    #
    attr_accessor :risk
    
    #
    # A string indicating the type of vulnerability
    #
    # @return   [String]
    #
    attr_accessor :name
    
    #
    # Description of the vulnerability
    #
    # @return   [String]
    #
    attr_accessor :description
    
    #
    # No idea what this is...
    #
    # @return   [String]
    #
    attr_accessor :category
    
    #
    # An arachni_* exploit of the MSF framework that is able to exploit this
    # type of vulnerability.
    #
    # Ex: unix/webapp/arachni_php_eval
    #
    # @return   [String]
    #
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
