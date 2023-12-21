#!/bin/bash
set -ex

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends wget tzdata ca-certificates git curl build-essential libfreetype6-dev libfontconfig-dev libcups2-dev libx11-dev libxext-dev libxrender-dev libxrandr-dev libxtst-dev libxt-dev libasound2-dev libffi-dev autoconf file unzip zip nano

# install maven
wget --no-check-certificate https://apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz -P /opt
tar xf /opt/apache-maven-*.tar.gz -C /opt
rm /opt/apache-maven-*-bin.tar.gz
mv /opt/apache-maven-3.9.6 /opt/maven


ARCH=$(uname -m)
export ARCH
case $ARCH in
    aarch64)   export BOOT_JDK_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.1%2B12/OpenJDK21U-jdk_aarch64_linux_hotspot_21.0.1_12.tar.gz" ;;
    *)       export BOOT_JDK_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.1%2B12/OpenJDK21U-jdk_x64_linux_hotspot_21.0.1_12.tar.gz" ;;
esac

mkdir -p /opt/mainline-jdk && cd /opt/mainline-jdk
curl -L ${BOOT_JDK_URL} | tar zx --strip-components=1
test -f /opt/mainline-jdk/bin/java
test -f /opt/mainline-jdk/bin/javac

cd /opt
git clone -b premain https://github.com/openjdk/leyden.git
cd leyden

bash configure --with-boot-jdk=/opt/mainline-jdk
make images
mv /opt/leyden/build/linux-$ARCH-server-release/images/jdk /opt/premain-jdk