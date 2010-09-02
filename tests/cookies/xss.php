<?php
/*
 * This page is used to test the XSS module.
 *
 */

if( !$_COOKIE['xss'] ) {
    setcookie( 'xss', 'xss' );
}


echo "<pre>";

echo <<<EOHTML
This page creates a cookie named "xss" that's vulnerable to Cross-site Scripting.
EOHTML;

echo "</pre>";


if( $_COOKIE['xss'] && $_COOKIE['xss'] != 'xss'  ) {
    echo $_COOKIE['xss'];
}

?>
