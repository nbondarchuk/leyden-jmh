if [ ! -d data ]; then
  mkdir data
fi
docker run --rm -it -v $(pwd)/data:/opt/leyden leyden-jmh