<?php
/*
 * This page is used to test the Eval module.
 *
 */


echo <<<EOHTML

    <pre>
This form is vulnerable to PHP code injection.
    </pre>

    <form method="get" action="{$_SERVER['PHP_SELF']}" name="eval_form">
    <p>
      <label>Eval</label>
      <input type="text" name="eval" value="">
      <input type="submit">
    </p>

    </form>

EOHTML;

if( $_GET['eval'] && $_GET['eval'] != 'eval'  ) {
    eval( "test" . $_GET['eval'] );
}

?>
