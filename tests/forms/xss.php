<?php
/*
 * This page is used to test the XSS module.
 *
 */

echo <<<EOHTML

    <pre>
This form is vulnerable to Cross-Site Scripting.
    </pre>

    <form method="post" action="{$_SERVER['PHP_SELF']}" name="xss_form">
    <p>
      <label>XSS</label>
      <input type="text" name="xss" value="">
      <input type="submit">
    </p>

    </form>

EOHTML;


if( $_POST['xss'] && $_POST['xss'] != 'xss'  ) {
    echo $_POST['xss'];
}

?>
