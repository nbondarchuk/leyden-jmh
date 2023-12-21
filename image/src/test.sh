#!/bin/bash
set -ex

cd /opt/leyden
if test -d leyden-jmh; then
  pushd leyden-jmh
  git pull origin main
  popd
else
  git clone -b main https://github.com/nbondarchuk/leyden-jmh.git
fi
cd leyden-jmh

chmod +x bench.sh
bash bench.sh /opt/premain-jdk /opt/mainline-jdk runAll