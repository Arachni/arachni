<?php
/*
 * This page is used to test the SQL injection module.
 *
 */

echo <<<EOHTML
    <pre>
This form is vulnerable to Blind SQL Injection.
    </pre>

<a href="{$_SERVER['PHP_SELF']}?id=1">SQL injection</a>
EOHTML;

if( $_GET['id'] ) {
    echo "<pre>";
    mysql_connect( 'localhost', 'root' );
    mysql_select_db( 'arachni' );

    $SQL['query']   =<<<SQL
SELECT *
  FROM content
 WHERE id='{$_GET['id']}'
SQL;

    $result = mysql_query( $SQL['query'] );

    while( $row = mysql_fetch_assoc( $result ) ) {
       $SQL['result'][]  = $row;
    }

    if( !$SQL['result'] ) {
        $SQL['result'] = 'Nothing found.';
    }


    $SQL['error'] = mysql_error();
    print_r( $SQL['result'] );
/*    print_r( $SQL['query'] );*/
/*    print_r( $SQL['error'] );*/
    echo "</pre>";
}

/*$log = '';
$log .= print_r( $_GET, true );
$log .= print_r( $_POST, true );
$log .= print_r( getallheaders( ), true );

file_put_contents( 'log.txt', $log );
*/
?>
