<?php
session_start();
session_destroy();
setcookie("role", "", time() - 3600, "/"); // مسح الكوكيز
header("Location: login.php");
?>
