=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

#
# Arachni::AuditStore class
#    
# Represents a finished audit session.<br/>
# It holds information about the runtime environment,
# the results of the audit etc...
#    
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1-pre
#
class AuditStore

    #
    # @return    [String]    the version of the framework
    #
    attr_reader :version
    
    #
    # @return    [String]    the SVN revision of the framework
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
    # @return    [Array<Vulnerability>]  the discovered vulnerabilities
    #
    attr_reader :vulns
    
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
    
    def initialize( audit = {} )
        
        # set instance variables from audit opts
        audit.each {
            |k, v|
            self.instance_variable_set( '@' + k, v )
        }
        
        @options         = prepare_options( @options )
        @vulns           = prepare_variations( @vulns )
        @start_datetime  = @options['start_datetime'].asctime
        @finish_datetime = @options['finish_datetime'].asctime
        @delta_time      = secs_to_hms( @options['delta_time'] )
    end
    
    #
    # Loads and returns an AuditStore object from file
    #
    # @param    [String]    file    the file to load
    #
    # @return    [AuditStore]
    #
    def AuditStore.load( file )
         YAML::load( IO.read( file ) )
    end
    
    #
    # Saves 'self' to file
    #
    # @param    [String]    file
    #
    def save( file )
        f = File.open( file, 'w' )
        YAML.dump( self, f )
    end
    
    #
    # Returns 'self' and all objects in its instance vars as hashes
    #
    # @return    [Hash]
    #
    def to_h

        hash = obj_to_hash( self )
        
        vulns = []
        hash['vulns'].each { 
            |vuln|
            vulns << obj_to_hash( vuln )
        }
        
        hash['vulns'] = vulns
        return hash
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
        hash = Hash.new
        obj.instance_variables.each {
            |var|
            hash[var.to_s.gsub( /@/, '' )] =
                obj.instance_variable_get( var ) 
        }
        hash
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
    # Parses the vulnerabilities in "vulns" and aggregates them
    # creating variations of the same attacks.
    #
    # @see Vulnerability#variations
    #
    # @param    [Array<Vulnerability>]    vulns
    #
    # @return    [Array<Vulnerability>]    new array of Vulnerability instances
    #                                        with populated {Vulnerability#variations}
    #
    def prepare_variations( vulns )
        
        variation_keys = [
            'injected',
            'id',
            'regexp',
            'regexp_match',
            'headers',
            'response'
        ]

        new_vulns = {}
        vulns.each {
            |vuln|
            
            __id  = vuln.mod_name + '::' + vuln.elem + '::' +
                vuln.var + '::' + vuln.url.split( /\?/ )[0]
                            
            orig_url    = vuln.url.clone
            vuln.url    = vuln.url.split( /\?/ )[0]
            
            if( !new_vulns[__id] )
                new_vulns[__id] = vuln.clone
            end

            if( !new_vulns[__id].variations )
                new_vulns[__id].variations = []
            end
            
            new_vulns[__id].variations << {
                'url'           => orig_url.clone,
                'injected'      => vuln.injected.clone,
                'id'            => vuln.id.clone,
                'regexp'        => vuln.regexp.clone,
                'regexp_match'  => vuln.regexp_match.clone,
                'headers'       => vuln.headers.clone,
                'response'      => vuln.response.clone
            }
            
            variation_keys.each {
                |key|
                
                if( new_vulns[__id].instance_variable_defined?( '@' + key ) )
                    new_vulns[__id].remove_instance_var( '@' + key )
                end
            }
            
        }
        
        vuln_keys = new_vulns.keys
        new_vulns = new_vulns.to_a.flatten
        
        vuln_keys.each {
            |key|
            new_vulns.delete( key )
        }
        
        new_vulns
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
