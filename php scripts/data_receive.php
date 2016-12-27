<?php
#Please don't kill me, I don't know PHP.
#I know this code is a security flaw.
#And I *might* fix it. Complain, and I won't.
$data = file_get_contents("php://input");
$postdata = explode("&", $data);
file_put_contents($postdata[0], $data, FILE_APPEND);
?>