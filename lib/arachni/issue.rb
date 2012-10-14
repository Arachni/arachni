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

require 'digest/sha2'

module Arachni

#
# Represents a detected issues.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Issue

    #
    # Holds constants to describe the {Issue#severity} of a
    # vulnerability.
    #
    module Severity
        HIGH          = 'High'
        MEDIUM        = 'Medium'
        LOW           = 'Low'
        INFORMATIONAL = 'Informational'
    end

    #
    # The name of the issue
    #
    # @return    [String]
    #
    attr_accessor :name

    #
    # The module that detected the issue
    #
    # @return    [String]    the name of the module
    #
    attr_accessor :mod_name

    #
    # The vulnerable HTTP variable
    #
    # @return    [String]    the name of the http variable
    #
    attr_accessor :var

    #
    # The vulnerable URL
    #
    # @return    [String]
    #
    attr_accessor :url

    #
    # The headers exchanged during the attack
    #
    # @return [Hash<Symbol, Hash>]  :request and :reply headers
    #
    attr_accessor :headers

    #
    # The HTML response of the attack
    #
    # @return [String]  the html response of the attack
    #
    attr_accessor :response

    #
    # The injected data that revealed the issue
    #
    # @return    [String]
    #
    attr_accessor :injected

    #
    # The string that identified the issue
    #
    # @return    [String]
    #
    attr_accessor :id

    #
    # The regexp that identified the issue
    #
    # @return    [String]
    #
    attr_reader   :regexp

    #
    # The data that was matched by the regexp
    #
    # @return    [String]
    #
    attr_accessor :regexp_match

    #
    # The vulnerable element, link, form or cookie
    #
    # @return    [String]
    #
    attr_accessor :elem

    #
    # HTTP method
    #
    # @return    [String]
    #
    attr_accessor :method

    #
    # The description of the issue
    #
    # @return    [String]
    #
    attr_accessor :description

    #
    # References related to the issue
    #
    # @return    [Hash]
    #
    attr_accessor :references

    #
    # The CWE ID number of the issue
    #
    # @return    [String]
    #
    attr_accessor :cwe

    #
    # The CWE URL of the issue
    #
    # @return    [String]
    #
    attr_accessor :cwe_url

    #
    # To be assigned a constant form {Severity}
    #
    # @see Severity
    #
    # @return    [String]
    #
    attr_accessor :severity

    #
    # The CVSS v2 score
    #
    # @return    [String]
    #
    attr_accessor :cvssv2

    #
    # A brief text informing the user how to remedy the situation
    #
    # @return    [String]
    #
    attr_accessor :remedy_guidance

    #
    # A code snippet showing the user how to remedy the situation
    #
    # @return    [String]
    #
    attr_accessor :remedy_code

    #
    # Placeholder variable to be populated by {AuditStore#prepare_variations}
    #
    # @see AuditStore#prepare_variations
    #
    attr_accessor :variations

    #
    # Is manual verification required?
    #
    # @return  [Bool]
    #
    attr_accessor :verification

    #
    # The Metasploit module that can exploit the vulnerability.
    #
    # ex. exploit/unix/webapp/php_include
    #
    # @return  [String]
    #
    attr_accessor :metasploitable

    # @return [Hash]    audit options associated with the issue
    attr_reader   :opts

    attr_accessor :internal_modname

    # @return [Array<String>]
    attr_accessor :tags

    #
    # Sets up the instance attributes
    #
    # @param    [Hash]    opts  configuration hash
    #                     Usually the returned data of a module's
    #                     info() method for the references
    #                     merged with a name=>value pair hash holding
    #                     class attributes
    #
    def initialize( opts = {} )
        @verification = false
        @references   = {}
        @opts         = { regexp: '' }

        opts.each do |k, v|
            begin
                send( "#{k.to_s.downcase}=", encode( v ) )
            rescue
            end
        end

        opts[:regexp] = opts[:regexp].to_s if opts[:regexp]
        opts[:issue].each do |k, v|
            begin
                send( "#{k.to_s.downcase}=", encode( v ) )
            rescue
            end
        end if opts[:issue]

        @headers ||= {}
        if opts[:headers] && opts[:headers][:request]
            @headers[:request] = {}.merge( opts[:headers][:request] )
        end
        @headers[:request] ||= {}

        if opts[:headers] && opts[:headers][:response]
            @headers[:response] = {}.merge( opts[:headers][:response] )
        end
        @headers[:response] ||= {}

        @response ||= ''

        @method   = @method.to_s.upcase
        @mod_name = opts[:name]

        # remove this block because it won't be able to be serialized
        @opts.delete( :each_mutation )
        @tags ||= []
    end

    def match
        self.regexp_match
    end

    def url=( v )
        @url = Utilities.normalize_url( v )

        # last resort sanitization
        @url = v.split( '?' ).first if @url.to_s.empty?
        @url
    end

    def cwe=( v )
        return if !v || v.to_s.empty?
        @cwe = v.to_s
        @cwe_url = "http://cwe.mitre.org/data/definitions/" + @cwe + ".html"
        @cwe
    end

    def references=( refs )
        @references = refs || {}
    end

    def regexp=( regexp )
        @regexp = regexp.to_s
    end

    def opts=( hash )
        if !hash
            @opts = { regexp: '' }
            return
        end
        hash[:regexp] = hash[:regexp].to_s
        @opts = hash.dup
    end

    def []( k )
        send( "#{k}" )
    rescue
        instance_variable_get( "@#{k.to_s}".to_sym )
    end

    def []=( k, v )
        v = encode( v )
        begin
            send( "#{k.to_s}=", v )
        rescue
            instance_variable_set( "@#{k.to_s}".to_sym, v )
        end
    end

    def each( &block )
        to_h.each( &block )
    end

    def each_pair( &block )
        to_h.each_pair( &block )
    end

    def to_h
        h = {}
        self.instance_variables.each do |var|
            h[normalize_name( var )] = instance_variable_get( var )
        end
        h[:digest] = h[:_hash] = digest
        h[:hash]  = hash
        h[:unique_id] = unique_id
        h
    end
    alias :to_hash :to_h

    def unique_id
        "#{@mod_name}::#{@elem}::#{@var}::#{@url.split( '?' ).first}"
    end

    def ==( other )
        hash == other.hash
    end

    def hash
        unique_id.hash
    end

    def digest
        Digest::SHA2.hexdigest( unique_id )
    end
    alias :_hash :digest

    def eql?( other )
        hash == other.hash
    end

    def remove_instance_var( var )
        remove_instance_variable( var )
    end

    private

    def encode( str )
        return str if !str.is_a?( String )
        str.recode
    end

    def normalize_name( name )
        name.to_s.gsub( /@/, '' )
    end

end
end

Arachni::Severity = Arachni::Issue::Severity
