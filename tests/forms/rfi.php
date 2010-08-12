<?php
/* $Id$ */
/*
 * This page is used to test the RFI module.
 *
 */

echo <<<EOHTML

    <pre>
This form is vulnerable to Remote File Inclusion
    </pre>

    <form method="post" action="{$_SERVER['PHP_SELF']}" name="rfi_form">
    <p>
      <label>RFI</label>
      <input type="text" name="rfi" value="">
      <input type="submit">
    </p>
    </form>

EOHTML;

if( $_POST['rfi'] && $_POST['rfi'] != 'rfi' ) {
    include( $_POST['rfi'] );
}

?>
