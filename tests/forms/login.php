<?php
/*
 * This page is used to test the cookiejar.
 *
 * You should login and then pass the cookiejar to Aarachni in order
 * to find the session protected vulnerabilities.
 *
 * You should also exclude the logout url to keep Arachni logged in.
 *
 */
session_start();

if( $_GET['logout'] ) {
    session_destroy();

    header( 'Location: ' .  $_SERVER['PHP_SELF'] );
}

// check that we have valid credentials and if so login the user in
if( $_POST['username'] == 'user' &&
    $_POST['password'] == 'pass' )
{
    $_SESSION['logged_in'] = true;

    header( 'Location: ' .  $_SERVER['PHP_SELF'] );
}

// if the user is not logged in show him the login form
if( !$_SESSION['logged_in'] ) {
  echo <<<EOHTML
    <form method="post" action="{$_SERVER['PHP_SELF']}">

    <p>
      <label>Username:</label>
      <input type="text" name="username" value=""> (user)
    </p>
    <p>
      <label>Password:</label>
      <input type="text" name="password" value=""> (pass)
    </p>
    <p>
      <input type="submit" value="Login">
    </p>
    </form>

EOHTML;
exit;

}

echo <<<EOHTML
    <p>
      <a href="?logout=true">Logout</a>
    </p>

    <form method="post" action="{$_SERVER['PHP_SELF']}" name="sql_inj_form">
    <p>
      <label>SQL Injection</label>
      <input type="text" name="sql_inj" value="">
      <input type="submit">
    </p>
    </form>


    <form method="post" action="{$_SERVER['PHP_SELF']}" name="rfi_form">
    <p>
      <label>RFI</label>
      <input type="text" name="rfi" value="">
      <input type="submit">
    </p>
    </form>

    <form method="post" action="{$_SERVER['PHP_SELF']}" name="xss_form">
    <p>
      <label>XSS</label>
      <input type="text" name="xss" value="">
      <input type="submit">
    </p>

    </form>

    <form method="post" action="{$_SERVER['PHP_SELF']}" name="eval_form">
    <p>
      <label>Eval</label>
      <input type="text" name="eval" value="">
      <input type="submit">
    </p>

    </form>

    <form method="post" action="{$_SERVER['PHP_SELF']}" name="os_comamnd_form">
    <p>
      <label>OS command</label>
      <input type="text" name="os_command" value="">
      <input type="submit">
    </p>

    </form>

EOHTML;

if( $_POST['rfi'] && $_POST['rfi'] != 'rfi' ) {
    include( $_POST['rfi'] );
}

if( $_POST['xss'] && $_POST['xss'] != 'xss'  ) {
    echo $_POST['xss'];
}

if( $_POST['eval'] && $_POST['eval'] != 'eval'  ) {
    eval( "test" . $_POST['eval'] );
}

if( $_POST['os_command'] && $_POST['os_command'] != 'os_command'  ) {
    echo "<pre>" . `{$_POST['os_command']}` . "</pre>";
}

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
    echo "</pre>";
}

?>
