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

require 'digest/md5'
module Arachni

require Options.instance.dir['lib'] + 'issue'

#
# Arachni::AuditStore class
#
# Represents a finished audit session.<br/>
# It holds information about the runtime environment,
# the results of the audit etc...
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.2
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

    MODULE_NAMESPACE = ::Arachni::Modules

    ORDER = [
        ::Arachni::Issue::Severity::HIGH,
        ::Arachni::Issue::Severity::MEDIUM,
        ::Arachni::Issue::Severity::LOW,
        ::Arachni::Issue::Severity::INFORMATIONAL
    ]

    def initialize( audit = {} )
        @plugins = {}
        @sitemap = []

        # set instance variables from audit opts
        audit.each {
            |k, v|
            self.instance_variable_set( '@' + k.to_s, v )
        }

        @options         = prepare_options( @options )
        @issues          = sort( prepare_variations( @issues ) )
        if @options['start_datetime']
            @start_datetime  = @options['start_datetime'].asctime
        else
            @start_datetime = Time.now.asctime
        end

        if @options['finish_datetime']
            @finish_datetime = @options['finish_datetime'].asctime
        else
            @finish_datetime = Time.now.asctime
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
    def AuditStore.load( file )
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
            File.open( file, 'w' ) {
                |f|
                f.write( YAML.dump( self ) )
            }
        rescue
            File.open( file, 'wb' ) {
                |f|
                f.write( Marshal.dump( self ) )
            }
        end
    end

    #
    # Returns 'self' and all objects in its instance vars as hashes
    #
    # @return    [Hash]
    #
    def to_h
        hash = obj_to_hash( self ).dup

        hash['issues'] = hash['issues'].map {
            |issue|
            issue.variations = issue.variations.map { |var| obj_to_hash( var ) }
            obj_to_hash( issue )
        }

        hash['plugins'].each {
            |plugin, results|
            next if !results[:options]

            hash['plugins'][plugin][:options] = hash['plugins'][plugin][:options].map {
                |opt|
                opt.to_h
            }
        }

        return hash
    end

    private

    def sort( issues )
        sorted = []
        issues.each {
            |issue|
            sorted[ORDER.rindex( issue.severity )] ||= []
            sorted[ORDER.rindex( issue.severity )] << issue
        }

        return sorted.flatten.reject{ |issue| issue.nil? }
    end


    #
    # Converts obj to hash
    #
    # @param    [Object]  obj    instance of an object
    #
    # @return    [Hash]
    #
    def obj_to_hash( obj )
        hash = {}
        obj.instance_variables.each {
            |var|
            key       = var.to_s.gsub( /@/, '' )
            hash[key] = obj.instance_variable_get( var )
        }
        return hash
    end

    #
    # Prepares the hash to be stored in {AuditStore#options}
    #
    # The 'options' dimention of the array that initializes AuditObjects<br/>
    # needs some more processing before being saved in {AuditStore#options}.
    #
    # @param    [Hash]
    #
    # @return    [Hash]
    #
    def prepare_options( options )
        options['url']    = options['url'].to_s

        new_options = Hash.new
        options.each_pair {
            |key, val|

            new_options[key.to_s]    = val

            case key

            when 'redundant'
                new_options[key.to_s] = []
                val.each {
                    |red|
                    new_options[key.to_s] << {
                        'regexp' => red['regexp'].to_s,
                         'count' => red['count']
                    }
                }

            when 'exclude', 'include'
                new_options[key.to_s] = []
                val.each {
                    |regexp|
                    new_options[key.to_s] << regexp.to_s
                }

            end

        }

        return new_options
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

        variation_keys = [
            'injected',
            'id',
            'regexp',
            'regexp_match',
            'headers',
            'response',
            'opts'
        ]

        new_issues = {}
        issues.each {
            |issue|

            var = issue.var || ''

            __id  = issue.mod_name +
                '::' + issue.elem + '::' +
                var + '::' +
                issue.url.split( /\?/ )[0].gsub( '//', '/' )

            orig_url  = issue.url
            issue.url = issue.url.split( /\?/ )[0]

            new_issues[__id] = issue         if !new_issues[__id]
            new_issues[__id].variations = [] if !new_issues[__id].variations

            issue.headers ||= {}

            issue.headers['request'] ||= {}
            (issue.headers[:request] || {}).each {
                |k, v|
                issue.headers['request'][k] = v.dup if v
            }

            issue.headers['response'] ||= {}
            issue.headers['response'] = (issue.headers[:response] || '').dup

            issue.headers.delete( :request )
            issue.headers.delete( :response )

            new_issues[__id]._hash = Digest::MD5.hexdigest( __id )
            new_issues[__id].internal_modname =
                get_internal_module_name( new_issues[__id].mod_name )
            new_issues[__id].variations << issue.deep_clone

            variation_keys.each {
                |key|
                if( new_issues[__id].instance_variable_defined?( '@' + key ) )
                    new_issues[__id].remove_instance_var( '@' + key )
                end
            }

        }

        issue_keys = new_issues.keys
        new_issues = new_issues.to_a.flatten

        issue_keys.each {
            |key|
            new_issues.delete( key )
        }

        new_issues
    end

    def get_internal_module_name( modname )
        MODULE_NAMESPACE.constants.each {
            |mod|
            klass = MODULE_NAMESPACE.const_get( mod )
            return mod.to_s if klass.info[:name] == modname
        }
    end

    #
    # Converts seconds to a (00:00:00) (hours:minutes:seconds) string
    #
    # @param    [String,Float,Integer]    seconds
    #
    # @return    [String]     hours:minutes:seconds
    #
    def secs_to_hms( secs )
        secs = secs.to_i
        return [secs/3600, secs/60 % 60, secs % 60].map {
            |t|
            t.to_s.rjust( 2, '0' )
        }.join(':')
    end

end

end
