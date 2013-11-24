=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'digest/sha2'

module Arachni

#
# Represents a detected issue.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class Issue

    # Holds constants to describe the {Issue#severity} of an Issue.
    module Severity
        HIGH          = 'High'
        MEDIUM        = 'Medium'
        LOW           = 'Low'
        INFORMATIONAL = 'Informational'
    end

    # @return    [String]   The name of the issue.
    attr_accessor :name

    # @return    [String]   The module that detected the issue.
    attr_accessor :mod_name

    # @return    [Symbol]   Name of the vulnerable platform.
    # @see Platform::Manager
    attr_accessor :platform

    # @return    [Symbol]   Type of the vulnerable platform.
    # @see Platform::Manager
    attr_accessor :platform_type

    # @return    [String]   The name of the vulnerable input.
    attr_accessor :var

    # @return    [String]   URL of the vulnerable resource.
    attr_accessor :url

    # @return [Hash<Symbol, Hash>]  `:request` and `:response` HTTP headers.
    attr_accessor :headers

    # @return [String]  The html response of the attack.
    attr_accessor :response

    # @return    [String]   The injected seed that revealed the issue.
    attr_accessor :injected

    # @return    [String]   The string that verified the issue.
    attr_accessor :id

    # @return    [String]   The regexp that identified the issue.
    attr_reader   :regexp

    # @return    [String]   The data that was matched by the regexp.
    attr_accessor :regexp_match

    # @return    [String]   Type of the vulnerable type.
    # @see Module::Auditor::OPTIONS
    attr_accessor :elem

    # @return    [String]   HTTP method used.
    attr_accessor :method

    # @return    [String]   Brief description of the issue.
    attr_accessor :description

    # @return    [Hash]     References related to the issue.
    attr_accessor :references

    # @return    [String]   The CWE ID number of the issue.
    # @see http://cwe.mitre.org/
    attr_accessor :cwe

    # @return    [String]   CWE URL of the issue
    # @see #cwe
    # @see http://cwe.mitre.org/
    attr_accessor :cwe_url

    # @return    [String]   Severity of the issue.
    # @see Severity
    attr_accessor :severity

    # @return    [String]   The CVSS v2 score.
    # @see http://nvd.nist.gov/cvss.cfm
    attr_accessor :cvssv2

    # @return    [String]
    #   A brief text informing the user how to remedy the Issue.
    attr_accessor :remedy_guidance

    # @return    [String]
    #   A code snippet showing the user how to remedy the Issue.
    attr_accessor :remedy_code

    #
    # Placeholder variable to be populated by {AuditStore#prepare_variations}
    #
    # @return   [Array<Issue>]  Variations of this issue.
    #
    # @see AuditStore#prepare_variations
    #
    attr_accessor :variations

    # @return  [Bool]   Is manual verification required?
    attr_accessor :verification

    # @return  [String]
    #   The Metasploit module that can exploit the vulnerability.
    attr_accessor :metasploitable

    # @return [Hash]    Audit options associated with the issue.
    attr_reader   :opts

    attr_accessor :internal_modname

    # @return [Array<String>]   Tags categorizing the issue.
    attr_accessor :tags

    # @return [Hash]
    #   Remarks about the issue. Key is the name of the entity which
    #   made the remark, value is an `Array` of remarks.
    attr_accessor :remarks

    #
    # Sets up the instance attributes.
    #
    # @param    [Hash]    opts
    #   Configuration hash. The returned data of a module's {Module::Base.info}
    #   method merged with a `Hash` holding {Issue} attributes.
    #
    def initialize( opts = {} )
        # Make sure we're dealing with UTF-8 data.
        opts = opts.recode

        @verification = false
        @references   = {}
        @opts         = { regexp: '' }

        opts.each do |k, v|
            send( "#{k.to_s.downcase}=", encode( v ) ) rescue nil
        end

        opts[:regexp] = opts[:regexp].to_s if opts[:regexp]
        opts[:issue].each do |k, v|
            send( "#{k.to_s.downcase}=", encode( v ) ) rescue nil
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

        @remarks ||= {}

        # remove this block because it won't be able to be serialized
        @opts.delete( :each_mutation )
        @tags ||= []
    end

    #
    # Adds a remark as a heads-up to the end user.
    #
    # @param    [String, Symbol]    author  Component which made the remark.
    # @param    [String]    string  Remark.
    #
    def add_remark( author, string )
        fail ArgumentError, 'Author cannot be blank.' if author.to_s.empty?
        fail ArgumentError, 'String cannot be blank.' if string.to_s.empty?

        (@remarks[author] ||= []) << string
    end

    # @return   [Boolean]
    #   `true` if the issue was discovered by manipulating an input,
    #   `false` otherwise.
    #
    # @see recon?
    #
    def audit?
        !!@var
    end

    # @return   [Boolean]
    #   `true` if the issue was discovered passively, `false` otherwise.
    #
    # @see audit?
    #
    def recon?
        !audit?
    end

    # @see #regexp_match
    def match
        self.regexp_match
    end

    # @return   [Bool]
    #   `true` if the issue requires manual verification, `false` otherwise.
    #
    # @see #verification
    def requires_verification?
        !!@verification
    end

    # @return   [Bool]
    #   `true` if the issue can be trusted (doesn't require manual verification),
    #   `false` otherwise.
    #
    # @see #requires_verification?
    def trusted?
        !requires_verification?
    end

    # @see #trusted?
    def untrusted?
        !trusted?
    end

    def url=( v )
        @url = Utilities.normalize_url( v )

        # Last resort sanitization.
        @url = v.split( '?' ).first if @url.to_s.empty?
        @url
    end

    def cwe=( v )
        return if !v || v.to_s.empty?
        @cwe = v.to_s
        @cwe_url = "http://cwe.mitre.org/data/definitions/#{@cwe}.html"
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

    # @return   [Hash]
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

    # @return   [String]    A string uniquely identifying this issue.
    def unique_id
        "#{@mod_name}::#{@elem}::#{@var}::#{@url.split( '?' ).first}"
    end

    # @return   [String]
    #   A SHA2 hash (of {#unique_id}) uniquely identifying this issue.
    #
    # @see #unique_id
    def digest
        Digest::SHA2.hexdigest( unique_id )
    end
    alias :_hash :digest

    def ==( other )
        hash == other.hash
    end

    def hash
        unique_id.hash
    end

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
