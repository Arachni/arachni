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
# Makes it easier to save and load audit results for the reports.
#    
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1-pre
#
class AuditStore

    attr_reader :audit
    
    def initialize( audit, loaded = false )
        
        @audit = audit

        if( loaded != true )
            @audit = prepare_data(  )
        end
        
    end
    
    def AuditStore.load( path )
        AuditStore.new( YAML::load( IO.read( path ) ), true )
    end
    
    def save( path )
        f = File.open( path, 'w' )
        YAML.dump( @audit, f )
    end
    
    private
    
    def prepare_data( )
        
        @audit = to_hash( )
        
        if( @audit['options']['exclude'] )
            @audit['options']['exclude'].each_with_index {
                |filter, i|
                @audit['options']['exclude'][i] = filter.to_s
            }
        end

        if( @audit['options']['include'] )
            @audit['options']['include'].each_with_index {
                |filter, i|
                @audit['options']['include'][i] = filter.to_s
            }
        end

        if( @audit['options']['redundant'] )
            @audit['options']['redundant'].each_with_index {
                |filter, i|
                @audit['options']['redundant'][i]['regexp'] =
                    filter['regexp'].to_s
            }
        end

        if( @audit['options']['cookies'] )
            cookies = []
            @audit['options']['cookies'].each_pair {
                |name, value|
                cookies << { 'name'=> name, 'value' => value }
            }
            @audit['options']['cookies'] = cookies
        end

        @audit['vulns'].each_with_index {
            |vuln, i|

            refs = []
            res_headers = []
            req_headers = []
            vuln['references'].each_pair {
                |name, value|
                refs << { 'name'=> name, 'value' => value }
            }

            vuln['headers']['response'].each_pair {
                |name, value|
                res_headers << "#{name}: #{value}"
            }
            
            vuln['headers']['request'].each_pair {
                |name, value|
                req_headers << "#{name}: #{value}"
            }
            
            @audit['vulns'][i]['__id']    =
                vuln['mod_name'] + '::' + vuln['elem'] + '::' +
                vuln['var'] + '::' + vuln['url'].split( /\?/ )[0]
                    
            @audit['vulns'][i]['headers']['request']  = req_headers            
            @audit['vulns'][i]['headers']['response'] = res_headers
            @audit['vulns'][i]['references']          = refs
        }
        
        runtime = @audit['options']['runtime'].to_i
        f_runtime = [runtime/3600, runtime/60 % 60, runtime % 60].map {
            |t|
            t.to_s.rjust( 2, '0' )
        }.join(':')
     
        return {
            'arachni' => {
                'version'  => @audit['version'],
                'revision' => @audit['revision'],
                'options'  => @audit['options']
            },
            'audit' => {
                'vulns'    => prepare_variations( @audit['vulns'] ),
                'start_datetime'  => @audit['options']['start_datetime'].asctime,
                'finish_datetime' => @audit['options']['finish_datetime'].asctime,
                'runtime'         => f_runtime
            }
        }
    end
    
    def prepare_variations( vulns )
        
        variation_keys = [
            'injected',
            'id',
            'regexp',
            'regexp_match',
            'headers',
            'response'
        ]
        
        new_vulns = Hash.new
        vulns.each {
            |vuln|
            
            orig_url    = vuln['url']
            vuln['url'] = vuln['url'].split( /\?/ )[0]
            
            if( !new_vulns[vuln['__id']] )
                new_vulns[vuln['__id']]    = vuln
            end

            if( !new_vulns[vuln['__id']]['variations'] )
                new_vulns[vuln['__id']]['variations'] = []
            end
            
            new_vulns[vuln['__id']]['variations'] << {
                'url'           => orig_url,
                'injected'      => vuln['injected'],
                'id'            => vuln['id'],
                'regexp'        => vuln['regexp'],
                'regexp_match'  => vuln['regexp_match'],
                'headers'       => vuln['headers'],
                'response'      => vuln['response']
            }
            
            variation_keys.each {
                |key|
                new_vulns[vuln['__id']].delete( key )
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
    
    def to_hash
        to_dump = Hash.new
        
        
        to_dump          = @audit.dup
        to_dump['vulns'] = []
        
        to_dump['options'] = Hash.new
        @audit['options'].each_pair {
            |key, value|
            to_dump['options'][normalize( key )] = value
        }
    
        to_dump['options']['url'] = @audit['options'][:url].to_s
        
        i = 0    
        @audit['vulns'].each {
            |vulnerability|
            
            to_dump['vulns'][i] = Hash.new
                
            vulnerability.each { 
                |vuln|
                to_dump['vulns'][i] = to_dump['vulns'][i].merge( vuln )
            }
            
            i += 1
        }

        return to_dump
    end

    def normalize( key )
        return key.to_s
    end

    
end

end