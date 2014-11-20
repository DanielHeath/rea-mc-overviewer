#!/bin/bash

set -ex # No more errors from here.

cd /home/ubuntu/minecraft/

source creds

trap 'poweroff' EXIT

apt-get install -y cloud-utils
EC2_INSTANCE_ID=$(ec2metadata --instance-id)

# because I did something dumb and baked a link into the AMI
rm "$HOST/$WORLD/$WORLD" || true # if missing who cares.

# We were stuck here on List permissions errors; have given this instance
# full S3 access which sucks but resolves the immediate issue.
# Restore S3 backup (fast)
aws s3 sync \
  --region ap-southeast-1 \
  s3://rea-minecraft-overviewer/backup "$HOST/$WORLD/"

# Get from ftp (slow but only has to get things that have changed)
wget --mirror "ftp://$USER:$PASS@$HOST/$WORLD"

# Push the world back to S3
aws s3 sync \
  --acl public-read \
  --storage-class REDUCED_REDUNDANCY \
  --region ap-southeast-1 \
  "$HOST/$WORLD" s3://rea-minecraft-overviewer/backup

wget https://raw.githubusercontent.com/DanielHeath/rea-mc-overviewer/gh-pages/overviewer.conf -O /home/ubuntu/minecraft/overviewer.conf

# Get the tiles we've already rendered back from S3
aws s3 sync \
  --region ap-southeast-1 \
  --exclude backup \
  s3://rea-minecraft-overviewer/ rea-render/

overviewer.py --config=/home/ubuntu/minecraft/overviewer.conf
overviewer.py --genpoi --config=/home/ubuntu/minecraft/overviewer.conf

# Push the tiles out to S3
aws s3 sync \
  --acl public-read \
  --storage-class REDUCED_REDUNDANCY \
  --exclude backup \
  --region ap-southeast-1 \
  rea-render/ s3://rea-minecraft-overviewer/

aws \
  ec2 \
  create-image \
  --region ap-southeast-2 \
  --instance-id "$EC2_INSTANCE_ID" \
  --name "`date '+%Y-%m-%d-%H-%M'` Minecraft map snapshot"

poweroff
