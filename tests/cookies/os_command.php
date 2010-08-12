<?php
/* $Id$ */
/*
 * This page is used to test the cookiejar.
 *
 * You should login and then pass the cookiejar to Aarachni in order
 * to find the session protected vulnerabilities.
 *
 * You should also exclude the logout url to keep Arachni logged in.
 *
 */

if( !$_COOKIE['os_command'] ) {
    setcookie( 'os_command', 'os_command' );
}

echo "<pre>";

echo <<<EOHTML
This page creates a cookie named "os_command" that's vulnerable to OS command injection.
EOHTML;

echo "</pre>";


if( $_COOKIE['os_command'] && $_COOKIE['os_command'] != 'os_command'  ) {
    echo "<pre>" . `{$_COOKIE['os_command']}` . "</pre>";
}

?>
