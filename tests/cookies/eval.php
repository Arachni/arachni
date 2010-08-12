<?php
/* $Id$ */
/*
 * This page is used to test the Eval module.
 *
 */

if( !$_COOKIE['eval'] ) {
    setcookie( 'eval', 'eval' );
}

echo "<pre>";

echo <<<EOHTML
This page creates a cookie named "eval" that's vulnerable to PHP  code injection.
EOHTML;

echo "</pre>";

if( $_COOKIE['eval'] && $_COOKIE['eval'] != 'eval'  ) {
    eval( "test" . $_COOKIE['eval'] );
}

?>
