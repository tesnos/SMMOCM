<?php
#Please don't kill me, I don't know PHP.
#I know this code is a security flaw.
#And I *might* fix it
echo file_put_contents($_GET['n'], $_GET['d'], FILE_APPEND);
?>