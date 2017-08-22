#!/bin/bash

set -euo pipefail

export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export PATH

export DEBIAN_FRONTEND=noninteractive
locale-gen en_US.UTF-8

apt-key update && apt-get update -qq
echo "-- Running apt-get dist-upgrade"
apt-get dist-upgrade -y
echo "-- Running apt-get install for misc tools"
apt-get install -y git curl sudo
