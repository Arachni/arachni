<?php
/*
 * This page is used to test the "backup_files" module.
 *
 */

/*
 * The actuall form is in index.php.bak
 * It should be discovered by "backup_files" and analyzed by
 * the trainer so that the XSS module can post it here and find the vulnerability.
 *
 */
if( $_POST['xss'] && $_POST['xss'] != 'xss'  ) {
    echo $_POST['xss'];
}

?>
