<?php

error_reporting( E_ALL );

echo <<<EOHTML

    <pre>
This form is vulnerable to RFI.
    </pre>

<a href="{$_SERVER['PHP_SELF']}?rfi=rfi">RFI</a>

EOHTML;


if( $_GET['rfi'] && $_GET['rfi'] != 'rfi'  ) {
    include( $_GET['rfi'] );
    print_r( $_GET['rfi'] );
    
}

?>
