<?php
/*
 * This page is used to test the XSS module.
 *
 */

echo <<<EOHTML

    <pre>
This form is vulnerable to Cross-Site Scripting.
    </pre>

<a href="{$_SERVER['PHP_SELF']}?xss=xss">XSS</a>

EOHTML;


if( $_GET['xss'] && $_GET['xss'] != 'xss'  ) {
    echo $_GET['xss'];
}

?>
