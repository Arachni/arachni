=begin
                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Reports    
    
#
# Default report.
#
# Outputs the vulnerabilities to stdout, used with the CLI UI.<br/>
# All UIs must have a default report.
#
#
# @author: Anastasios "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class Stdout < Arachni::Report::Base
    
    # register us with the system
    include Arachni::Report::Registrar
    
    #
    # @param [AuditStore]  audit_store
    # @param [Hash]   options    options passed to the report
    # @param [String]    outfile    where to save the report
    #
    def initialize( audit_store, options = nil, outfile = nil )
        @audit_store = audit_store
    end
    
    #
    # REQUIRED
    #
    # Use it to run your report.
    #
    def run( )
        
        print_line( )
        print_ok( @audit_store.vulns.size.to_s + ' vulnerabilities were detected.' )
        print_line( )
        
        @audit_store.vulns.each {
            |vuln|
            
            print_ok( vuln.name )
            print_info( '**************' )
            
            vuln.each_pair {
                |key, val|
                
                case key
                
                when 'cwe_url', 'name'
                    next
                    
                when 'mod_name'
                    print_info( "Module name: #{val}" )
                
                when 'references'
                    
                    print_line( )
                    key = key.gsub( /_/, ' ' ).capitalize
                    print_info( "#{key}:" )

                    val.each_pair {
                        |ref, url|
                        print_info( "\t#{ref}:\t\t#{url}" )
                    }
                    print_line( )


                when 'remedy_guidance', 'remedy_code'
                    if( val.size == 0 ) then next end
                        
                    print_line( )
                    
                    key = key.gsub( /_/, ' ' ).capitalize
                    print_info( "#{key}:" )
                    print_info( "-----------" )
                    print_line( "#{val}" )
                    print_line( )
                
                when 'cwe'
                    print_info( key.upcase + ': ' + val + " <#{vuln.cwe_url}>" )
                    
                when 'variations'
                    print_line( )
                    print_info( 'Variations' )
                    
                    val.each_with_index {
                        |variation, i|
                        print_info( '#' + (i+1).to_s )
                        variation.each_pair {
                            |name, item|
                            if( item.is_a?( String ) && name != 'response' )
                                print_info( "\t#{name}" + ': ' + item )
                            end
                        }
                        
                        print_line( )
                    }
                    
                else
                    __print_generic( key, val )
                end
                
            }
            
            print_line( )
            print_line( '-----' )
            print_line( 'Found a false positive?' )
            print_line( 'Report it: ' + REPORT_FP )
            print_line( '-----' )
            
            print_line( )
            print_line( )
        }
    end
    
    #
    # REQUIRED
    #
    # Do not ommit any of the info.
    #
    def self.info
        {
            :name           => 'Stdout',
            :description    => %q{Prints the results to standard output.},
            :author         => 'zapotek',
            :version        => '0.1',
        }
    end
    
    def __print_generic( key, val )
        key = key.gsub( /_/, ' ' ).capitalize
        
        if( val.instance_of?( String ) )
            print_info( key + ': ' + val )
        elsif( val.instance_of?( Array ) )
            print_line( )
            print_info( key + ':' )
            val.each {
                |item|
                print_info( "\t" + item.strip )
            }
            print_line( )
        else
            print_line( )
            print_info( key + ':' )
            val.each_pair {
                |name, item|
                print_info( "\t#{name}:\t" + item.strip )
            }
            print_line( )
        end

    end
    
end

end
end
