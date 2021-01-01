#!/bin/sh

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
	</head>
	<body>
		<header class='navbar'>
			<a href='/stream'>Stream</a>
			<a href='/media'>Files</a>
			<a href=':8080'>Motion web page</a>
		</header>
		<section class='content'>
			<a href='/stream'>
				<img src='/stream'>
			</a>
		</section>
	</body>
</html>
"

set_param() {
	# file parameter value
	sudo sed -i "s|^\s*;?\s*$2 .*$|$2 $3|g" "$1"
}


#sudo apt-get -y install autoconf automake build-essential pkgconf libtool git libzip-dev libjpeg-dev gettext libmicrohttpd-dev libavformat-dev libavcodec-dev libavutil-dev libswscale-dev libavdevice-dev default-libmysqlclient-dev libpq-dev libsqlite3-dev libwebp-dev

# project location is https://github.com/Motion-Project/motion
sudo apt-get -y install nginx
wget https://github.com/JSkrat/linux-scripts/raw/main/camera%20server/pi_buster_motion_4.3.2-1_armhf.deb
sudo apt -y install "./pi_buster_motion_4.3.2-1_armhf.deb"

# setup motion
CONFIG="/etc/motion/motion.conf"
# first fill up initially unexistent parameters
grep "locate_motion_mode" "$CONFIG" || echo "locate_motion_mode preview" | sudo tee -a "$CONFIG"
grep "locate_motion_style" "$CONFIG" || echo "locate_motion_style redbox" | sudo tee -a "$CONFIG"
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
echo "$MOTION_SITE" | sudo tee "$NGINX_CONF"
sudo ln -s "$NGINX_CONF" "/etc/nginx/sites-enabled/motion-static"
sudo rm "/etc/nginx/sites-enabled/default"
# add static
sudo mkdir -p "/var/www/motion"
echo "$INDEX_HTML" | sudo tee "/var/www/motion/index.html"
# make media readable
sudo chmod o+rx "/var/lib/motion"

sudo service nginx reload
