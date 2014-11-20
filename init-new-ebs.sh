#!/bin/bash

set -ex # No more errors from here.

echo 'deb http://overviewer.org/debian ./' >> /etc/apt/sources.list
wget -O - http://overviewer.org/debian/overviewer.gpg.asc | sudo apt-key add -
apt-get update
apt-get install -y minecraft-overviewer awscli cloud-utils

mkdir -p /home/ubuntu/minecraft/
cd /home/ubuntu/minecraft/

echo 'export USER=' >> /home/ubuntu/minecraft/creds
echo 'export PASS='    >> /home/ubuntu/minecraft/creds
echo 'export HOST=119.81.65.252'       >> /home/ubuntu/minecraft/creds
echo 'export WORLD=oki3'               >> /home/ubuntu/minecraft/creds

wget https://s3.amazonaws.com/Minecraft.Download/versions/1.8/1.8.jar -O /home/ubuntu/minecraft/1.8.jar

# We were stuck here on List permissions errors; have given this instance
# full S3 access which sucks but resolves the immediate issue.

# Restore S3 backup (fast)
mkdir -p $HOST/$WORLD
aws s3 sync \
  --acl public-read \
  --storage-class REDUCED_REDUNDANCY \
  --region ap-southeast-1 \
  s3://rea-minecraft-overviewer/backup $HOST/$WORLD

# Give it a handy name.
ln -s $HOST/$WORLD rea
