=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

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

    attr_accessor :framework


    ORDER = [
        ::Arachni::Issue::Severity::HIGH,
        ::Arachni::Issue::Severity::MEDIUM,
        ::Arachni::Issue::Severity::LOW,
        ::Arachni::Issue::Severity::INFORMATIONAL
    ]

    def initialize( audit = {}, framework )

        @framework = framework

        # set instance variables from audit opts
        audit.each {
            |k, v|
            self.instance_variable_set( '@' + k.to_s, v )
        }

        @options         = prepare_options( @options )
        @issues          = sort( prepare_variations( @issues ) )
        @start_datetime  = @options['start_datetime'].asctime

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
        @framework = ''
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
        hash.delete( 'framework' )

        issues = []
        hash['issues'].each {
            |issue|
            issues << obj_to_hash( issue )
        }

        hash['issues'] = issues

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
        hash = Hash.new
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
                issue.url.split( /\?/ )[0]

            orig_url  = issue.url
            issue.url = issue.url.split( /\?/ )[0]

            if( !new_issues[__id] )
                new_issues[__id] = issue
            end

            if( !new_issues[__id].variations )
                new_issues[__id].variations = []
            end

            issue.headers ||= {}
            issue.headers['request']  = issue.headers[:request] || {}
            issue.headers['response'] = issue.headers[:response] || {}

            new_issues[__id]._hash = Digest::MD5.hexdigest( __id )

            modname = ''
            @framework.modules.each_pair {
                |name, mod|

                if mod.info[:name] == new_issues[__id].mod_name
                    modname = name
                    break
                end
            }

            new_issues[__id].internal_modname = modname

            new_issues[__id].variations << {
                'url'           => orig_url,
                'injected'      => issue.injected,
                'id'            => issue.id,
                'regexp'        => issue.regexp,
                'regexp_match'  => issue.regexp_match,
                'headers'       => issue.headers,
                'response'      => issue.response,
                'opts'          => issue.opts ? issue.opts : {}
            }

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
