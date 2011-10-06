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
    $_SESSION['__csrf'] = md5( rand(  ) );

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

    <form method="get" action="{$_SERVER['PHP_SELF']}" name="csrf_form">
    <p>
      <label>Vulnerable form</label>
      <input type="text" name="vuln" value="">
      <input type="submit">
    </p>
    </form>

EOHTML;


if( $_REQUEST['vuln'] ) {
    echo "<pre>";

    if( $_SESSION['__csrf'] != $_REQUEST['__csrf'] ) {
        echo 'Invalid CSRF token...';
        exit;
    }

    echo 'Ok...';

    echo "</pre>";
}

?>
