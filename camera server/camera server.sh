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
sudo sed -i "s|daemon |daemon on|g" "$CONFIG"
sudo sed -i "s|stream_localhost |stream_localhost off|g" "$CONFIG"
sudo sed -i "s|webcontrol_localhost |webcontrol_localhost off|g" "$CONFIG"

sudo sed -i "s|mmalcam_name |mmalcam_name vc.ril.camera|g" "$CONFIG"
sudo sed -i "s|event_gap |event_gap 10|g" "$CONFIG"
sudo sed -i "s|target_dir |target_dir /var/lib/motion|g" "$CONFIG"
sudo sed -i "s|locate_motion_mode |locate_motion_mode preview|g" "$CONFIG"
sudo sed -i "s|locate_motion_style |locate_motion_style redbox|g" "$CONFIG"
# for stream freezes
sudo sed -i "s|picture_output |picture_output off|g" "$CONFIG"
sudo sed -i "s|movie_output |movie_output on|g" "$CONFIG"

DEFCONF="/etc/default/motion"
sudo sed -i "s|start_motion_daemon=|start_motion_daemon=yes|g" "$DEFCONF"

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
