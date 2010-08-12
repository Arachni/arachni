<?php
/* $Id$ */
/*
 * This page is used to test the RFI module.
 *
 */

if( !$_COOKIE['rfi'] ) {
    setcookie( 'rfi', 'rfi' );
}

echo "<pre>";

echo <<<EOHTML
This page creates a cookie named "rfi" that's vulnerable to remote file inclusion.
EOHTML;

echo "</pre>";


if( $_COOKIE['rfi'] && $_COOKIE['rfi'] != 'rfi' ) {
    include( $_COOKIE['rfi'] );
}

?>
