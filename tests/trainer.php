<?php
/*
 * This page is used to test the trainer.
 *
 * It has nested forms that should be posted before the vulnerable GET var
 * "msg" appears in the redirection URL.
 *
 * It also tests cookie preservation since the php session has to be preserved
 * in order for the form traversal to work properly.
 *
 * Finally, this script is also vulnerable to script name/path XSS injection.
 *
 */
error_reporting( E_ALL ^ E_NOTICE );

session_start();

/*
 * $_SESSION['curveball'] will be in a hidden field in the second form
 * and be valided before the 3rd form appears.
 *
 */
if( !$_SESSION['curveball'] ) {
  $_SESSION['curveball'] = md5( rand( 0, 99999 ) );
}

if( $_POST['form3_input'] == "form three input" ) {
  session_destroy();
  header( 'Location: ?msg=Congrats!+You+made+it!' );

}

if( $_POST['form2_input'] == "form two input" &&
    $_POST['curveball'] == $_SESSION['curveball'] )
{
  setcookie( 'rfi', 'rfi' );

  echo <<<EOHTML

    <form method="post" action="{$_SERVER['PHP_SELF']}?form3" name="form3">
    <label>Form 3 input:</label>
    <input type="text" name="form3_input" value="form three input">
    <input type="submit">
    </form>
EOHTML;


}

if(  $_POST['form1_input'] == "form one input" ) {

  echo <<<EOHTML

    <form method="post" action="{$_SERVER['PHP_SELF']}?form2" name="form2">
    <label>Form 2 input:</label>
    <input type="text" name="form2_input" value="form two input">
    <input type="hidden" name="curveball" value="{$_SESSION['curveball']}">
    <input type="submit">
    </form>
EOHTML;

}


echo <<<EOHTML

<pre>
This page is used to test the trainer.

It has nested forms that should be posted before the vulnerable GET var
"msg" appears in the redirection URL.

It also tests cookie preservation since the php session has to be preserved
in order for the form traversal to work properly.

Finally, this script is also vulnerable to script name/path XSS injection.
</pre>

    {$_GET['msg']}
    <br/>
    <br/>
    <form method="post" action="{$_SERVER['PHP_SELF']}?form1" name="form1">
    <label>Form 1 input:</label>
    <input type="text" name="form1_input" value="form one input">
    <input type="submit">
    </form>
EOHTML;

if( $_COOKIE['rfi'] && $_COOKIE['rfi'] != 'rfi')
    include( $_COOKIE['rfi'] );


