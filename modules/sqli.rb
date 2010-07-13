=begin
  $Id$

                  Arachni
  Copyright (c) 2010 Anastasios Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LINCENSE file for details)

=end

module Arachni

module Modules

#
# SQL Injection recon module.
# It audits links, forms and cookies.
#
#
# @author: Zapotek <zapotek@segfault.gr> <br/>
# @version: $Rev: 64 $
#
class SQLInjection < Arachni::Module

    include Arachni::ModuleRegistrar
    include Arachni::UI::Output

    def initialize( page_data, structure )
        super( page_data, structure )

        @__id = @__injection_strs = []
        
        @results = Hash.new
        @results['links'] = []
        @results['forms'] = []
        @results['cookies'] = []
    end

    def prepare( )
        @__id = [
            'System.Data.OleDb.OleDbException',
            '[SQL Server]',
            '[Microsoft][ODBC SQL Server Driver]',
            '[SQLServer JDBC Driver]',
            '[SqlException',
            'System.Data.SqlClient.SqlException',
            'Unclosed quotation mark after the character string',
            "'80040e14'",
            'mssql_query()',
            'odbc_exec()',
            'Microsoft OLE DB Provider for ODBC Drivers',
            'Microsoft OLE DB Provider for SQL Server',
            'Incorrect syntax near',
            'Sintaxis incorrecta cerca de',
            'Syntax error in string in query expression',
            'ADODB.Field (0x800A0BCD)<br>',
            "Procedure '[^']+' requires parameter '[^']+'",
            "ADODB.Recordset'",
            "Unclosed quotation mark before the character string",
            'SQLCODE',
            'DB2 SQL error:',
            'SQLSTATE',
            '[IBM][CLI Driver][DB2/6000]',
            '[CLI Driver]',
            '[DB2/6000]',
            "Sybase message:",
            'Syntax error in query expression',
            'Data type mismatch in criteria expression.',
            'Microsoft JET Database Engine',
            '[Microsoft][ODBC Microsoft Access Driver]',
            '(PLS|ORA)-[0-9][0-9][0-9][0-9]',
            'PostgreSQL query failed:',
            'supplied argument is not a valid PostgreSQL result',
            'pg_query() [:',
            'pg_exec() [:',
            'supplied argument is not a valid MySQL',
            'Column count doesn\'t match value count at row',
            'mysql_fetch_array()',
            'mysql_',
            'on MySQL result index',
            'You have an error in your SQL syntax;',
            'You have an error in your SQL syntax near',
            'MySQL server version for the right syntax to use',
            '[MySQL][ODBC',
            "Column count doesn't match",
            "the used select statements have different number of columns",
            "Table '[^']+' doesn't exist",
            'com.informix.jdbc',
            'Dynamic Page Generation Error:',
            'An illegal character has been found in the statement',
            '<b>Warning</b>: ibase_',
            'Dynamic SQL Error',
            '[DM_QUERY_E_SYNTAX]',
            'has occurred in the vicinity of:',
            'A Parser Error (syntax error)',
            'java.sql.SQLException',
            'Unexpected end of command in statement',
            '[Macromedia][SQLServer JDBC Driver]',
            'SELECT .*? FROM .*?',
            'UPDATE .*? SET .*?',
            'INSERT INTO .*?',
            'Unknown column',
            'where clause',
            'SqlServer'
        ]
        
        @__injection_strs = [
            '\'',
            '--',
            ';'
        ]
        
    end
    
    def run( )
        
        @__injection_strs.each {
            |str|
            
            audit_forms( str ) {
                |var, res|
                __log_results( 'forms', var, res )
            }
                    
            audit_links( str ) {
                |var, res|
                __log_results( 'links', var, res )
            }
                    
            audit_cookies( str ) {
                |var, res|
                __log_results( 'cookies', var, res )
            }
        }
        
        register_results( { 'SQLInjection' => @results } )
    end

    
    def self.info
        {
            'Name'           => 'SQLInjection',
            'Description'    => %q{SQL injection recon module},
            'Author'         => 'zapotek',
            'Version'        => '$Rev: 64 $',
            'References'     => {
            },
            'Targets'        => { 'Generic' => 'all' }
        }
    end
    
    private
    
    def __log_results( where, var, res )
        
        for id in @__id
            regex = Regexp.new( Regexp.escape( id ) )
            
            if ( res.body.scan( regex )[0] )
            
                @results[where] << { var => page_data['url']['href'] }
                                
                print_ok( "SQL injection found in: #{where} var #{var}" +
                            '::' + page_data['url']['href'] )
            end
            
        end
        
    end

end
end
end
