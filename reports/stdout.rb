=begin
  $Id$

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
# @version: $Rev$
#
class Stdout < Arachni::Report::Base
    
    # register us with the system
    include Arachni::Report::Registrar
    
    # get the output interface
    include Arachni::UI::Output

    #
    # @param [Array<Vulnerability>]  vulns  the array of detected vulnerabilities
    # @param [Hash]   options    options passed to the report
    # @param [String]    outfile    where to save the report
    #
    def initialize( audit, options = nil, outfile = nil )
        @audit = audit
    end
    
    #
    # REQUIRED
    #
    # Use it to run your report.
    #
    def run( )
        
        print_line( )
        print_ok( @audit['vulns'].size.to_s + ' vulnerabilities were detected.' )
        print_line( )
        
        @audit['vulns'].each {
            |vuln|
            
            print_ok( vuln.mod_name )
            print_info( '**************' )
            
            vuln.each_pair {
                |key, val|
                
                case key
                
                when 'mod_name', 'response', 'cwe_url'
                    next
                
                when 'headers'
                    print_line( )
                    print_info( 'Headers:')
                    print_info( '----------' )
                    print_line( )
                    
                    print_info( "\tRequest" )
                    print_info( "\t----------" )
                    val['request'].each_pair {
                        |name, value|

                        splits = value.split( "\n" )
                        if( splits.size == 1 )
                            print_info( "\t#{name}: #{value}" )
                        else
                            splits.each {
                                |line|
                                print_info( "\t\t#{line}" )
                            }
                        end
                        
                    }
                    
                    print_line( )
                    print_info( "\tResponse" )
                    print_info( "\t----------" )
                    val['response'].each_pair {
                        |name, value|

                        splits = value.split( "\n" )
                        if( splits.size == 1 )
                            print_info( "\t#{name}: #{value}" )
                        else
                            print_info( "\t#{name}:" )
                            splits.each {
                                |line|
                                print_info( "\t\t#{line}" )
                            }
                        end
                    }
                    print_line( )

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
                    
                else
                    key = key.gsub( /_/, ' ' ).capitalize
                    
                    if( val.instance_of?( String ) )
                        print_info( key + ': ' + val )
                    else
                        print_line( )
                        print_info( key + ':' )
                        val.each {
                            |item|
                            print_info( "\t" + item.strip )
                        }
                        print_line( )
                    end 
                    
                end
                
            }
            
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
            'Name'           => 'Stdout',
            'Description'    => %q{Prints the results to standard output.
                (Not Marshal dump safe, should only be used by the framework directly.)},
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
        }
    end
    
end

end
end
