#!/bin/sh

CONFIG_VERSION='1.0'

MOTION_SITE='
server {
	listen 80;
	root /var/www/motion;
	location /media {
		alias /var/lib/motion/;
		autoindex on;
	}
	location /stream {
		proxy_pass http://localhost:8081;
	}
	location / {
		try_files $uri $uri/ /index.html;
	}
}
'

INDEX_HTML="
<!DOCTYPE html>
<html lang='en'>
	<head>
		<style>
			.navbar, .content {
				text-align: center;
				margin-top: 1em;
			}
			.navbar a {
				margin-left: 1ex;
				margin-right: 1ex;
			}
			body {
				background-color: #111;
				color: white;
				font-family: Arial, Helvetica, sans-serif;
			}
			a {
				color: #AAF;
			}
			a:hover {
				text-shadow: white 0 0 1em;
			}
			.right {
				position: absolute;
				right: 1ex;
			}
		</style>
	</head>
	<body>
		<header class='navbar'>
			<div class='right'><a href='https://github.com/JSkrat/linux-scripts/tree/main/camera%20server'>CamServer</a> ver $CONFIG_VERSION</div>
			<a href='/media'>Files</a>
			<a href='/stream'>Stream</a>
			<button onclick='javascript:event.target.port=8080'>Motion web page</button>
		</header>
		<section class='content'>
			<p>
				<a href='/stream'>
					<img src='/stream'>
				</a>
			</p>
		</section>
	</body>
</html>
"

set_param() {
	# file parameter value
	sudo sed -i "s|^\s*;\?\s*$2 .*$|$2 $3|g" "$1"
}

# it's for building motion
# sudo apt-get -y install autoconf automake build-essential pkgconf libtool git libzip-dev libjpeg-dev gettext libmicrohttpd-dev libavformat-dev libavcodec-dev libavutil-dev libswscale-dev libavdevice-dev default-libmysqlclient-dev libpq-dev libsqlite3-dev libwebp-dev

# project location is https://github.com/Motion-Project/motion
sudo apt-get -y install nginx
wget https://github.com/JSkrat/linux-scripts/raw/main/camera%20server/pi_buster_motion_4.3.2-1_armhf.deb
sudo apt -y install "./pi_buster_motion_4.3.2-1_armhf.deb"
rm "./pi_buster_motion_4.3.2-1_armhf.deb"

# setup motion (TODO: creating a separate config would be so much nicer)
CONFIG="/etc/motion/motion.conf"
# first fill up initially unexistent parameters
grep "locate_motion_mode" "$CONFIG" > /dev/null || echo "locate_motion_mode preview" | sudo tee -a "$CONFIG" > /dev/null
grep "locate_motion_style" "$CONFIG" > /dev/null || echo "locate_motion_style redbox" | sudo tee -a "$CONFIG" > /dev/null
# update changes
set_param "$CONFIG" "daemon" "on"
set_param "$CONFIG" "stream_localhost" "off"
set_param "$CONFIG" "webcontrol_localhost" "off"

set_param "$CONFIG" "mmalcam_name" "vc.ril.camera"
set_param "$CONFIG" "event_gap" "10"
set_param "$CONFIG" "target_dir" "/var/lib/motion"
set_param "$CONFIG" "locate_motion_mode" "preview"
set_param "$CONFIG" "locate_motion_style" "redbox"
set_param "$CONFIG" "picture_output" "off"
set_param "$CONFIG" "movie_output" "on"

DEFCONF="/etc/default/motion"
sudo sed -i "s|^start_motion_daemon=.*$|start_motion_daemon=yes|g" "$DEFCONF"

sudo service motion restart

# setup nginx for file browser
NGINX_CONF='/etc/nginx/sites-available/motion-static'
echo "$MOTION_SITE" | sudo tee "$NGINX_CONF" > /dev/null
sudo ln -s "$NGINX_CONF" "/etc/nginx/sites-enabled/motion-static"
sudo rm "/etc/nginx/sites-enabled/default"
# add static
sudo mkdir -p "/var/www/motion"
echo "$INDEX_HTML" | sudo tee "/var/www/motion/index.html" > /dev/null
# make media readable
sudo chmod o+rx "/var/lib/motion"

sudo service nginx reload

