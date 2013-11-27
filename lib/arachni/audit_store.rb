=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end

require 'digest/md5'
module Arachni

require Options.dir['lib'] + 'issue'

#
# Represents a finished audit session.
#
# It holds information about the runtime environment,
# the results of the audit etc...
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
#
class AuditStore

    #
    # @return    [String]    the version of the framework
    #
    attr_reader :version

    #
    # @return    [String]    the revision of the framework class
    #
    attr_reader :revision

    #
    # @return    [Hash]    the runtime arguments/options of the environment
    #
    attr_reader :options

    #
    # @return    [Array]   all the urls crawled
    #
    attr_reader :sitemap

    #
    # @return    [Array<Issue>]  the discovered issues
    #
    attr_reader :issues

    #
    # @return    [Hash]  plugin results
    #
    attr_reader :plugins

    #
    # @return    [String]    the date and time when the audit started
    #
    attr_reader :start_datetime

    #
    # @return    [String]    the date and time when the audit finished
    #
    attr_reader :finish_datetime

    #
    # @return    [String]    how long the audit took
    #
    attr_reader :delta_time

    MODULE_NAMESPACE = ::Arachni::Checks

    def initialize( opts = {} )
        @plugins = {}
        @sitemap = []

        @issues  ||= []
        @options ||= Options

        # set instance variables from audit opts
        opts.each { |k, v| self.instance_variable_set( '@' + k.to_s, v ) }

        @options = prepare_options( @options )
        @issues  = Issue.sort( prepare_variations( @issues.deep_clone ) )

        @start_datetime  =  if @options['start_datetime']
            @options['start_datetime'].asctime
        else
            Time.now.asctime
        end

        @finish_datetime = if @options['finish_datetime']
            @options['finish_datetime'].asctime
        else
            Time.now.asctime
        end

        @delta_time = secs_to_hms( @options['delta_time'] )
    end

    #
    # Loads and returns an AuditStore object from file
    #
    # @param    [String]    file    the file to load
    #
    # @return    [AuditStore]
    #
    def self.load( file )
         begin
             r = YAML.load( IO.read( file ) )
             r.version
             r
         rescue Exception => e
             Marshal.load( File.binread( file ) )
         end
    end

    #
    # Saves 'self' to file
    #
    # @param    [String]    file
    #
    def save( file )
        begin
            File.open( file, 'w' ) { |f| f.write( YAML.dump( self ) ) }
        rescue
            File.open( file, 'wb' ) { |f| f.write( Marshal.dump( self ) ) }
        end
    end

    #
    # Returns 'self' and all objects in its instance vars as hashes
    #
    # @return    [Hash]
    #
    def to_hash
        hash = obj_to_hash( self ).deep_clone

        hash['issues'] = hash['issues'].map do |issue|
            issue.variations = issue.variations.map { |var| obj_to_hash( var ) }
            obj_to_hash( issue )
        end

        hash['plugins'].each do |plugin, results|
            next if !results[:options]

            hash['plugins'][plugin][:options] =
                hash['plugins'][plugin][:options].map { |opt| opt.to_h }
        end

        hash
    end
    alias :to_h :to_hash

    def ==( other )
        to_hash == other.to_hash
    end

    def hash
        to_hash.hash
    end

    private

    #
    # Converts obj to hash
    #
    # @param    [Object]  obj    instance of an object
    #
    # @return    [Hash]
    #
    def obj_to_hash( obj )
        hash = {}
        obj.instance_variables.each do |var|
            hash[var.to_s.gsub( /@/, '' )] = obj.instance_variable_get( var )
        end
        hash
    end

    #
    # Prepares the hash to be stored in {AuditStore#options}
    #
    # The value of the 'options' key of the hash that initializes AuditObjects
    # needs some more processing before being saved in {AuditStore#options}.
    #
    # @param    [Hash]  options
    #
    # @return    [Hash]
    #
    def prepare_options( options )
        new_options = {}

        options = options.to_hash
        options.each_pair do |key, val|
            case key
                when 'redundant'
                    new_options[key.to_s] = {}
                    val.each do |regexp, counter|
                        new_options[key.to_s].merge!( regexp.to_s => counter )
                    end

                when 'exclude', 'include'
                    new_options[key.to_s] = []
                    val.each { |regexp| new_options[key.to_s] << regexp.to_s }

                when 'cookies'
                    next if !val
                    new_options[key.to_s] =
                        val.inject( {} ){ |h, c| h.merge!( c.simple ) }

                else
                    new_options[key.to_s] = val
            end
        end

        new_options
    end

    #
    # Parses the issues in "issue" and aggregates them
    # creating variations of the same attacks.
    #
    # @see Issue#variations
    #
    # @param    [Array<Issue>]    issues
    #
    # @return    [Array<Issue>]    new array of Issue instances
    #                                        with populated {Issue#variations}
    #
    def prepare_variations( issues )
        variation_keys = %w(injected id regexp regexp_match headers response opts remarks)

        new_issues = {}
        issues.each do |issue|
            __id  = issue.hash
            new_issues[__id] ||= issue
            new_issues[__id].variations ||= []

            issue.headers ||= {}

            issue.headers['request'] ||= {}
            (issue.headers[:request] || {}).each do |k, v|
                issue.headers['request'][k] = v.dup if v
            end

            issue.headers['response'] ||= {}
            issue.headers['response'] = (issue.headers[:response] || '').dup

            issue.headers.delete( :request )
            issue.headers.delete( :response )

            new_issues[__id].internal_modname ||=
                get_internal_check_name( new_issues[__id].mod_name )
            new_issues[__id].variations << issue.deep_clone

            variation_keys.each do |key|
                if new_issues[__id].instance_variable_defined?( '@' + key )
                    new_issues[__id].remove_instance_var( '@' + key )
                end
            end
        end

        new_issues.values.each do |i|
            next if !i.variations || !i.injected
            i.variations.each do |v|
                v.remove_instance_var( :@variations ) rescue next
            end
        end

        issue_keys = new_issues.keys
        new_issues = new_issues.to_a.flatten

        issue_keys.each { |key| new_issues.delete( key ) }
        new_issues
    end

    def get_internal_check_name( modname )
        MODULE_NAMESPACE.constants.each do |mod|
            klass = MODULE_NAMESPACE.const_get( mod )
            return mod.to_s if klass.info[:name] == modname
        end
    end

    #
    # Converts seconds to a (00:00:00) (hours:minutes:seconds) string
    #
    # @param    [String,Float,Integer]    secs    seconds
    #
    # @return    [String]     hours:minutes:seconds
    #
    def secs_to_hms( secs )
        secs = secs.to_i
        [secs/3600, secs/60 % 60, secs % 60].map { |t| t.to_s.rjust( 2, '0' ) }.join( ':' )
    end

end

end
