<?php
/*
 * This page is used to test the XSS module.
 *
 */

if( $_GET['redir'] ) {
    header( 'Location: ' . $_GET['redir'] );
}
 
echo <<<EOHTML

    <pre>
This form is vulnerable to unvalidated redirection.
    </pre>

<a href="{$_SERVER['PHP_SELF']}?redir=http://google.com">Redir</a>

EOHTML;

?>
