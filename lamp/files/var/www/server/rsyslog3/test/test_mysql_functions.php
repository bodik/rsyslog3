<?php

if ( 
	(function_exists("mysqli_real_escape_string") == true) and
	(function_exists("mysqli_connect") == true)
) {
		print("mysql functions present");
	} else {
		header("HTTP/1.0 500 Internal Server Error");
	}
?>
