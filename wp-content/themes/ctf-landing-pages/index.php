<?php
// Fallback index required by WordPress themes
?><!doctype html>
<html>
<head>
	<meta charset="utf-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1" />
	<title>CTF Test Site</title>
	<?php wp_head(); ?>
</head>
<body>
	<?php wp_body_open(); ?>
	<main style="max-width: 720px; margin: 40px auto; padding: 0 16px;">
		<h1>CTF WordPress Test</h1>
		<p>If you see this, the theme is active.</p>
		<p>Go to <a href="/wp-admin/">/wp-admin/</a> to manage the site.</p>
	</main>
	<?php wp_footer(); ?>
</body>
</html>

