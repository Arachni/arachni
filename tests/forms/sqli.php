<?php
/*
 * This page is used to test the SQL injection module.
 *
 */

echo <<<EOHTML
    <pre>
This form is vulnerable to SQL injection.
    </pre>

    <form method="post" action="{$_SERVER['PHP_SELF']}" name="sql_inj_form">
    <p>
      <label>SQL Injection</label>
      <input type="text" name="sql_inj" value="">
      <input type="submit">
    </p>
    </form>
EOHTML;

if( $_POST['sql_inj'] && $_POST['sql_inj'] != 'sql_inj' ) {
    echo "<pre>";
    mysql_connect( 'localhost', 'root' );
    mysql_select_db( 'arachni' );

    $SQL['query']   =<<<SQL
SELECT *
  FROM content
 WHERE id={$_POST['sql_inj']}
SQL;

    $result = mysql_query( $SQL['query'] );

    while( $row = mysql_fetch_assoc( $result ) ) {
       $SQL['result'][]  = $row;
    }

    $SQL['error'] = mysql_error();
    print_r( $SQL );
    echo "</pre>";
}

?>
