<?php
?><!doctype html>
<html>
<head>
	<meta charset="utf-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1" />
	<title>Welcome | CTF</title>
	<?php wp_head(); ?>
	<style>
		:root {
			--bg: #0b1324;
			--card: #141c2f;
			--text: #eef2f7;
			--muted: #aab3c5;
			--accent: #5b8def;
		}
		body { margin:0; font-family: system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif; background: var(--bg); color: var(--text); }
		.container { max-width: 960px; margin: 64px auto; padding: 0 20px; }
		.hero { background: linear-gradient(135deg, rgba(91,141,239,.15), rgba(91,141,239,0)); border: 1px solid rgba(255,255,255,.08); border-radius: 16px; padding: 32px; }
		h1 { margin: 0 0 12px; font-size: 32px; }
		p { margin: 0 0 16px; color: var(--muted); }
		.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 16px; margin-top: 24px; }
		.card { background: var(--card); border: 1px solid rgba(255,255,255,.08); border-radius: 12px; padding: 16px; }
		.card h3 { margin: 0 0 8px; font-size: 18px; }
		.card a { color: var(--accent); text-decoration: none; }
	</style>
</head>
<body>
	<?php wp_body_open(); ?>
	<div class="container">
		<div class="hero">
			<h1>CTF hello world</h1>
			<p>Basic main page for testing the local environment.</p>
		</div>
		<div class="grid">
			<div class="card">
				<h3>Admin</h3>
				<p><a href="/wp-admin/">Open dashboard</a></p>
			</div>
			<div class="card">
				<h3>Permalinks</h3>
				<p>After login, visit Settings → Permalinks and click Save.</p>
			</div>
			<div class="card">
				<h3>Mailchimp</h3>
				<p>Set `MAILCHIMP_API_KEY` in `docker-compose.yml` if testing.</p>
			</div>
		</div>
	</div>
	<?php wp_footer(); ?>
</body>
</html>

