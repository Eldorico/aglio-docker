#!/bin/sh -eux
# docker-provision.sh --- Provisioning script for a Docker container w/Aglio.
AGLIO_VERSION="2.3.0"
FONT_AWESOME_VERSION="4.4.0"
ASSETS_DIR=/aglio/assets


# General packages needed to build Node modules. This list is based on the list
# in https://github.com/docker-library/buildpack-deps/blob/master/jessie/Dockerfile
BUILD_PKGS="autoconf automake bzip2 file g++ gcc git imagemagick libbz2-dev libc6-dev libcurl4-openssl-dev libevent-dev libffi-dev libgeoip-dev libglib2.0-dev libjpeg-dev liblzma-dev libmagickcore-dev libmagickwand-dev libmysqlclient-dev libncurses-dev libpng-dev libpq-dev libreadline-dev libsqlite3-dev libssl-dev libtool libwebp-dev libxml2-dev libxslt-dev libyaml-dev make patch xz-utils zlib1g-dev"


# move data into place
mkdir -p /aglio
mv /tmp/templates /aglio
mv /tmp/assets /aglio
mv /tmp/aglio-wrapper.sh /usr/local/bin/


# update Apt repositories
apt-get update


# install build packages
apt-get install -y --no-install-recommends $BUILD_PKGS


# install Aglio
npm install -g aglio@$AGLIO_VERSION


# Download external assets used by the "Olio" theme engine
cd /aglio/assets
npm install
npm run fonts

mkdir -p $ASSETS_DIR/fonts

mv node_modules/font-awesome/fonts/*.* $ASSETS_DIR/fonts
mv googlewebfonts/fonts/fonts/* $ASSETS_DIR/fonts
mv node_modules/font-awesome/css $ASSETS_DIR
rm -rf node_modules

# get zepto
git clone https://github.com/madrobby/zepto.git
cd zepto
npm install
MODULES="zepto event ajax ie selector" npm run-script dist
mkdir -p /aglio/assets/js
cp dist/zepto.min.js $ASSETS_DIR/js
cd ..
rm -rf zepto


# Create a custom theme engine based on Olio
cp -R /usr/local/lib/node_modules/aglio/node_modules/aglio-theme-olio /tmp/aglio-theme-olio-local
cd /tmp/aglio-theme-olio-local

# 1. edit package.json (change name and description)
sed -i \
    -e '/"name": "aglio-theme-olio"/s/olio/olio-local/' \
    -e '/"description"/s/\("description": \)\(.*\)/\1"Modified verison of the default Olio theme that references local assets.",/' \
    package.json

# 2. edit templates/index.jade (swap css for local and remove footer)
sed -i \
    -e '/link/s|https://maxcdn.bootstrapcdn.com/font-awesome/[^/]*/||' \
    -e "/p.text.muted/,/format('DD MMM YYYY')}$/d" \
    templates/index.jade

# 3. edit styles/variables-defaults.less (comment out google fonts)
sed -i \
    -e '/^@import/s||//&|p' \
    styles/variables-default.less

# 4. install custom package
npm install -g

# 5. remove dir
cd /tmp
rm -r aglio-theme-olio-local


# remove installation dependencies
apt-get -y purge $BUILD_PKGS
apt-get -y clean
apt-get -y autoremove
rm -rf /var/lib/apt/lists/* /root/.npm /tmp/npm*


# Add empty docs directory
mkdir -p /docs
