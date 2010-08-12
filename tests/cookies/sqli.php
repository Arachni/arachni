<?php
/* $Id$ */
/*
 * This page is used to test the SQL injection module.
 *
 */

if( !$_COOKIE['sql_inj'] ) {
    setcookie( 'sql_inj', 'sql_inj' );
}

echo "<pre>";

echo <<<EOHTML
This page creates a cookie named "sql_inj" that's vulnerable to SQL injection.
EOHTML;

echo "</pre>";


if( $_COOKIE['sql_inj'] && $_COOKIE['sql_inj'] != 'sql_inj' ) {
    echo "<pre>";
    mysql_connect( 'localhost', 'root' );
    mysql_select_db( 'arachni' );

    $SQL['query']   =<<<SQL
SELECT *
  FROM content
 WHERE id={$_COOKIE['sql_inj']}
SQL;

    $result = mysql_query( $SQL['query'] );

    while( $row = mysql_fetch_assoc( $result ) ) {
       $SQL['result'][]  = $row;
    }

    $SQL['error'] = mysql_error();
    echo "</pre>";
}

?>
