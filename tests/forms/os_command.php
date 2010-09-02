<?php
/*
 * This page is used to test the cookiejar.
 *
 * You should login and then pass the cookiejar to Aarachni in order
 * to find the session protected vulnerabilities.
 *
 * You should also exclude the logout url to keep Arachni logged in.
 *
 */

echo <<<EOHTML
    <pre>
This form is vulnerable to OS Command injection.
    </pre>

    <form method="post" action="{$_SERVER['PHP_SELF']}" name="os_comamnd_form">
    <p>
      <label>OS command</label>
      <input type="text" name="os_command" value="">
      <input type="submit">
    </p>

    </form>

EOHTML;

if( $_POST['os_command'] && $_POST['os_command'] != 'os_command'  ) {
    echo "<pre>" . `{$_POST['os_command']}` . "</pre>";
}

?>
