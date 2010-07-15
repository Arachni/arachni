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
# @version: $Rev$
#
class SQLInjection < Arachni::Module

    # register us with the system
    include Arachni::ModuleRegistrar
    # get output module
    include Arachni::UI::Output

    def initialize( page_data, structure )
        super( page_data, structure )

        # initialize variables 
        @__id = []
        @__injection_strs = []
        
        # initialize the results hash
        @results = Hash.new
        @results['links'] = []
        @results['forms'] = []
        @results['cookies'] = []
    end

    def prepare( )
        
        # prepare the regular expressions that will id SQL error messages
        @__id  = %q{
        System.Data.OleDb.OleDbException
        \[SQL Server\]
        \[Microsoft\]\[ODBC SQL Server Driver\]
        \[SQLServer JDBC Driver\]
        \[SqlException
        System.Data.SqlClient.SqlException
        Unclosed quotation mark after the character string
        '80040e14'
        mssql_query\(\)
        odbc_exec\(\)
        Microsoft OLE DB Provider for ODBC Drivers
        Microsoft OLE DB Provider for SQL Server
        Incorrect syntax near
        Sintaxis incorrecta cerca de
        Syntax error in string in query expression
        ADODB.Field \(0x800A0BCD\)<br>
        Procedure '[^']+' requires parameter '[^']+'
        ADODB.Recordset\'
        Unclosed quotation mark before the character string
        SQLCODE
        DB2 SQL error:
        SQLSTATE
        \[IBM\]\[CLI Driver\]\[DB26000\]
        \[CLI Driver\]
        \[DB26000\]
        Sybase message:
        Syntax error in query expression
        Data type mismatch in criteria expression.
        Microsoft JET Database Engine
        \[Microsoft\]\[ODBC Microsoft Access Driver\]
        (PLS|ORA)-[0-9][0-9][0-9][0-9]
        PostgreSQL query failed:
        supplied argument is not a valid PostgreSQL result
        pg_query\(\) \[:
        pg_exec\(\) \[:
        supplied argument is not a valid MySQL
        Column count doesn't match value count at row
        mysql_fetch_array\(\)
        mysql_
        on MySQL result index
        You have an error in your SQL syntax;
        You have an error in your SQL syntax near
        MySQL server version for the right syntax to use
        \[MySQL\]\[ODBC
        Column count doesn't match
        the used select statements have different number of columns
        Table '[^']+' doesn't exist
        com.informix.jdbc
        Dynamic Page Generation Error:
        An illegal character has been found in the statement
        <b>Warning<b>: ibase_
        Dynamic SQL Error
        \[DM_QUERY_E_SYNTAX\]
        has occurred in the vicinity of:
        A Parser Error \(syntax error\)
        java\.sql\.SQLException
        Unexpected end of command in statement
        \[Macromedia\]\[SQLServer JDBC Driver\]
        SELECT .*? FROM .*?
        UPDATE .*? SET .*?
        INSERT INTO .*?
        Unknown column
        where clause
        SqlServer
        }
        
        # prepare the strings that will hopefully cause the webapp
        # to output SQL error messages
        @__injection_strs = [
            '\'',
            '--',
            ';',
            '`'
        ]
        
    end
    
    def run( )
        
        # iterate through the regular expression strings
        @__injection_strs.each {
            |str|
            
            # send the bad characters in @__injection_strs via the page forms
            # and pass a block that will check for a positive result
            audit_forms( str ) {
                |var, res|
                __log_results( 'forms', var, res, str )
            }
            
            # send the bad characters in @__injection_strs via link vars
            # and pass a block that will check for a positive result        
            audit_links( str ) {
                |var, res|
                __log_results( 'links', var, res, str )
            }
                    
            # send the bad characters in @__injection_strs via cookies
            # and pass a block that will check for a positive result
            audit_cookies( str ) {
                |var, res|
                __log_results( 'cookies', var, res, str )
            }
        }
        
        # register our results with the framework
        register_results( { 'SQLInjection' => @results } )
    end

    
    def self.info
        {
            'Name'           => 'SQLInjection',
            'Description'    => %q{SQL injection recon module},
            'Author'         => 'zapotek',
            'Version'        => '$Rev$',
            'References'     => {
                'UnixWiz'    => 'http://unixwiz.net/techtips/sql-injection.html',
                'Wikipedia'  => 'http://en.wikipedia.org/wiki/SQL_injection',
                'SecuriTeam' => 'http://www.securiteam.com/securityreviews/5DP0N1P76E.html',
                'OWASP'      => 'http://www.owasp.org/index.php/SQL_Injection'
            },
            'Targets'        => { 'Generic' => 'all' }
        }
    end
    
    private
    
    def __log_results( where, var, res, injection_str )
        
        # iterate through the regular expressions in @__id
        # and try to match them with the body of the HTTP response
        for id in @__id.each_line
            
            # strip whitespace from the regexp
            id = id.strip
            
            # just to make sure...
            if id.size == 0 then next end
            
            # create a regular expression from the regexp strings
            id_regex = Regexp.new( id )
            
            # try to match them with the body of the HTTP response,
            # if it matches we have a positive result
            if ( res.body.scan( id_regex )[0] &&
                 res.body.scan( id_regex )[0].size > 0 )
                
                # append the result to the results hash
                @results[where] << {
                    'var'   => var,
                    'url'   => page_data['url']['href'],
                    'audit' => {
                        'inj'     => injection_str,
                        'id'      => id,
                        'regex'   => id_regex.to_s
                    }
                }
        
                # inform the user that we have a match
                print_ok( self.class.info['Name'] +
                    " in: #{where} var #{var}" +
                    '::' + page_data['url']['href'] )
                
                # give the user some more info if he wants 
                print_verbose( "Injected str:\t" + injection_str )    
                print_verbose( "ID str:\t\t" + id )
                print_verbose( "Matched regex:\t" + id_regex.to_s )
                print_verbose( '---------' ) if only_positives?

            end
            
        end
        
    end

end
end
end
