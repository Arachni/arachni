<?php

error_reporting( E_ALL );

echo <<<EOHTML

    <pre>
This form is vulnerable to Cross-Site Scripting.
    </pre>

<a href="{$_SERVER['PHP_SELF']}?xpath=xpath">XSS</a>

EOHTML;


$xmlStr = <<<EOHTML
<books>
   <book id="bk1">
      <title>XML Developer's Guide</title>
      <genre>Computer</genre>
      <price>44.95</price>
   </book>
   <book id="bk2">
      <author>Ralls, Kim</author>
      <title>Midnight Rain</title>
      <genre>Fantasy</genre>
      <price>5.95</price>
   </book>
</books>
EOHTML;


$xml = new SimpleXMLElement( $xmlStr );

if( $_GET['xpath'] && $_GET['xpath'] != 'xpath'  ) {
    $res = $xml->xpath( "//book/id[.='". $_GET['xpath'] . "']" );

    print_r( $res );

}

?>
