<?php
$link = mysql_connect('127.0.0.1', '2589-kalkulace', 'zADZtuzLEWHa');
if (!$link) {
    die('Could not connect');
}
$db_selected = mysql_select_db('2589-kalkulace', $link);
if (!$db_selected) {
    die ('Can not use db');
}
mysql_set_charset('utf8',$link);

?>