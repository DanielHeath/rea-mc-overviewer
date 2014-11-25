#!/bin/bash -ex

ssh \
  -o UserKnownHostsFile=/dev/null \
  -o StrictHostKeyChecking=no \
  -i ~/.ssh/minecraftspot \
  ubuntu@$@
